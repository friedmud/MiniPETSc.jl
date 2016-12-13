abstract PetscVecBase <: AbstractArray{PetscScalar}

"""
    A PETSc Vec wrapper.
"""
type PetscVec <: PetscVecBase

    " The pointer to the PETSc Vec object "
    vec::Ref{Vec}

    " Whether or not a size has been set by calling setSize() "
    sized::Bool

    " Whether or not the vector has ever been assembled (Note: the vector might currently NOT be assembled) "
    assembled::Bool

    name::String

    function PetscVec()
#        println("Creating PetscVec")
        vec = Ref{Vec}()
        ccall((:VecCreate, library), PetscErrorCode, (comm_type, Ref{Vec}), MPI.COMM_WORLD, vec)
        ccall((:VecSetType, library), PetscErrorCode, (Vec, VecType), vec[], VECMPI)
        new_vec = new(vec, false, false, "")

        function finalize(avec)
#            ccall((:VecDestroy, library), PetscErrorCode, (Ref{Vec},), avec.vec)
#            println(avec.name)
        end

        finalizer(new_vec, finalize)

        return new_vec
    end

    function PetscVec(name::String)
#        println("Creating ", name)
        new_vec = PetscVec()
        new_vec.name = name
        return new_vec
    end
end


"""
    A PETSc Vec wrapper for Ghosted Vectors.
"""
type GhostedPetscVec <: PetscVecBase

    " The pointer to the PETSc Vec object "
    vec::Ref{Vec}

    " Whether or not a size has been set. "
    sized::Bool

    " Whether or not the vector has ever been assembled (Note: the vector might currently NOT be assembled) "
    assembled::Bool

    " Maps global indices to local indices "
    global_to_local_map::Dict{PetscInt, PetscInt}

    " The first index on this processor (1-based)"
    first_local_index::PetscInt

    " The last index on this processor (1-based)"
    last_local_index::PetscInt

    " Whether or not the raw array is present "
    raw_array_present::Bool

    " The raw local array.  This shouldn't be accessed directly!  Use [] to access values. (1-based)"
    raw_array::Array{PetscScalar}

    " The local form.  Only present if the raw_array is.  Only for internal use!"
    local_form::PetscVec

    function GhostedPetscVec{T}(ghosts::Array{T};
                                n_local::PetscInt=PETSC_DECIDE, n_global::PetscInt=PETSC_DETERMINE)
        vec = Ref{Vec}()
        ghost_dofs = (PetscInt)[dof-1 for dof in ghosts]
        ccall((:VecCreateGhost, library), PetscErrorCode, (comm_type, PetscInt, PetscInt, PetscInt, Ptr{PetscInt}, Ref{Vec}),
              MPI.COMM_WORLD, n_local, n_global, length(ghost_dofs), ghost_dofs, vec)

        first = Ref{PetscInt}()
        last = Ref{PetscInt}()

        ccall((:VecGetOwnershipRange, library), PetscErrorCode, (Vec, Ref{PetscInt}, Ref{PetscInt}), vec[], first, last)

        # +1 is for 1-based indexing
        new_vec = new(vec, true, false, Dict{PetscInt, PetscInt}(), first[]+1, last[], false)

        # Need to set up the global_to_local map
        for i in 1:length(ghosts)
            new_vec.global_to_local_map[ghosts[i]] = i + (last[]-first[])
        end

        # This idea comes from libMesh
        # mapping = Ref{ISLocalToGlobalMapping}()

        # ccall((:VecGetLocalToGlobalMapping, library), PetscErrorCode, (Vec, Ref{ISLocalToGlobalMapping}), vec[], mapping)

        # println("mapping: ", mapping)

        # indices_ptr = Ref{Ptr{PetscInt}}()

        # ccall((:ISLocalToGlobalMappingGetIndices, library), PetscErrorCode, (ISLocalToGlobalMapping, Ref{Ptr{PetscInt}}), mapping[], indices_ptr)

        # println("indices_ptr: ", indices_ptr)

        # mapping_size = Ref{PetscInt}()

        # ccall((:ISLocalToGlobalMappingGetSize, library), PetscErrorCode, (ISLocalToGlobalMapping, Ref{PetscInt}), mapping[], mapping_size)

        # println("mapping_size: ", mapping_size)

        # indices = unsafe_wrap(Array, indices_ptr[], mapping_size[], false)

        # if MPI.Comm_rank(MPI.COMM_WORLD) == 0
        #     println("indices: ", indices)
        # end

        # for i in 1:length(indices)
        #     if indices[i]+1 < new_vec.first_local_index || new_vec.last_local_index < indices[i]+1
        #         new_vec.global_to_local_map[indices[i]+1] = i
        #     end
        # end

        # if MPI.Comm_rank(MPI.COMM_WORLD) == 0
        #     println(new_vec.global_to_local_map)
        # end

        # ccall((:ISLocalToGlobalMappingRestoreIndices, library), PetscErrorCode, (ISLocalToGlobalMapping, Ref{Ptr{PetscInt}}), mapping[], indices_ptr)

        return new_vec
    end
end


"""
    Set up the size of a PetscVecBase

    Note: This MUST be called before setting/getting values!
"""
function setSize!(vec::PetscVecBase; n_local::PetscInt=PETSC_DECIDE, n_global::PetscInt=PETSC_DETERMINE)
    @assert !vec.sized

    # Must provide _some_ size!
    @assert n_local != PETSC_DECIDE || n_global != PETSC_DETERMINE

    ccall((:VecSetSizes, library), PetscErrorCode, (Vec, PetscInt, PetscInt), vec.vec[], n_local, n_global)

    vec.sized = true
end

"""
    Must be called after setting/adding values to construct the vector
"""
function assemble!(vec::PetscVecBase)
    @assert vec.sized

    ccall((:VecAssemblyBegin, library), PetscErrorCode, (Vec,), vec.vec[])
    ccall((:VecAssemblyEnd, library), PetscErrorCode, (Vec,), vec.vec[])

    vec.assembled = true
end

"""
    Must be called after setting/adding values to construct the vector
"""
function assemble!(vec::GhostedPetscVec)
    @assert vec.sized

    _restoreArray(vec)

    ccall((:VecAssemblyBegin, library), PetscErrorCode, (Vec,), vec.vec[])
    ccall((:VecAssemblyEnd, library), PetscErrorCode, (Vec,), vec.vec[])

    ccall((:VecGhostUpdateBegin, library), PetscErrorCode, (Vec, InsertMode, ScatterMode), vec.vec[], INSERT_VALUES, SCATTER_FORWARD)
    ccall((:VecGhostUpdateEnd, library), PetscErrorCode, (Vec, InsertMode, ScatterMode), vec.vec[], INSERT_VALUES, SCATTER_FORWARD)

    vec.assembled = true
end

"""
    Use PETSc viewer to print out the vector
"""
function viewVec(vec::PetscVecBase)
    @assert vec.sized
    @assert vec.assembled

    viewer = ccall((:PETSC_VIEWER_STDOUT_, library), PetscViewer, (comm_type,), MPI.COMM_WORLD)
    ccall((:VecView, library), PetscErrorCode, (Vec, PetscViewer), vec.vec[], viewer)
end

"""
    Does vec[i] += v
"""
function plusEquals!(vec::PetscVecBase, v::Array{Float64}, i)
    i_ind = (PetscInt)[i_val-1 for i_val in i]

    @assert length(v) == length(i_ind)

    ccall((:VecSetValues, library), PetscErrorCode, (Vec, PetscInt, Ptr{PetscInt}, Ptr{PetscScalar}, InsertMode), vec.vec[], length(i_ind), i_ind, v, ADD_VALUES)
end

"""
    If the incoming type is not a float, make it so

    Does vec[i] += v
"""
function plusEquals!{T}(vec::PetscVecBase, v::Array{T}, i)
    plusEquals!(vec, (Float64)[(Float64)(val) for val in v], i)
end

"""
    vec += v
"""
function plusEquals!(vec::PetscVecBase, v::PetscVecBase)
    ccall((:VecAXPY, library), PetscErrorCode, (Vec, PetscScalar, Vec), vec.vec[], 1.0, v.vec[])
end

"""
    vec = 0
"""
function zero!(vec::PetscVecBase)
    ccall((:VecZeroEntries, library), PetscErrorCode, (Vec,), vec.vec[])
end

"""
    vec = a*vec
"""
function scale!(vec::PetscVecBase, a::Real)
    ccall((:VecScale, library), PetscErrorCode, (Vec, PetscScalar), vec.vec[], (PetscScalar)(a))
end

import Base.copy!

"""
    vec = a
"""
function copy!(vec::PetscVecBase, a::PetscVecBase)
    # NOTE!  PETSc's calling sequence is _backwards_ from Julia!
    # The destination is the _second_ argument for PETSc
    ccall((:VecCopy, library), PetscErrorCode, (Vec, Vec), a.vec[], vec.vec[])
end

"""
    vec = a when "vec" is a ghosted vec
"""
function copy!(vec::GhostedPetscVec, a::PetscVecBase)
    # Basic idea here: copy over the purely local data directly
    # then use assemble!() to update the ghosts

    # This happens in five steps
    # 1. Get the local form and array for the destination (vec)
    # 2. Get the array for the src (a)
    # 3. Copy local values
    # 4. Restore everything
    # 5. Call assemble!() to update ghosts

    # 1:
    local_and_ghosted_data_array = _getArray(vec)

    # 2:
    src_local_array = _getArray(a)

    @assert length(local_and_ghosted_data_array) >= length(src_local_array)

    # 3:
    for i in 1:length(src_local_array)
        local_and_ghosted_data_array[i] = src_local_array[i]
    end

    # 4:
    _restoreArray(a, src_local_array)
    _restoreArray(vec)

    # 5:
    assemble!(vec)
end

import Base.similar
"""
    Creates a PetscVec() with the same storage as the passed in vector
"""
function similar(vec::PetscVec)
    new_vec = PetscVec()

    ccall((:VecDuplicate, library), PetscErrorCode, (Vec, Ref{Vec}), vec.vec[], new_vec.vec)

    return new_vec
end

import Base.norm
"""
    L2 Norm
"""
function norm(vec::PetscVecBase)
    norm_value = Ref{PetscScalar}()

    ccall((:VecNorm, library), PetscErrorCode, (Vec, NormType, Ref{PetscScalar}), vec.vec[], NORM_2, norm_value)

    return norm_value[]
end

"""
    Serializes a parallel PETSc vec down into a Julia Array

    Only returns the array on processor 0
"""
function serializeToZero(vec::PetscVecBase)
    serialized_vec = PetscVec("serialized_vec")
    scatter = Ref{VecScatter}()

    ccall((:VecScatterCreateToZero, library), PetscErrorCode, (Vec, Ref{VecScatter}, Ref{Vec}), vec.vec[], scatter, serialized_vec.vec)

    ccall((:VecScatterBegin, library), PetscErrorCode, (VecScatter, Vec, Vec, InsertMode, ScatterMode), scatter[], vec.vec[], serialized_vec.vec[], INSERT_VALUES, SCATTER_FORWARD)
    ccall((:VecScatterEnd, library), PetscErrorCode, (VecScatter, Vec, Vec, InsertMode, ScatterMode), scatter[], vec.vec[], serialized_vec.vec[], INSERT_VALUES, SCATTER_FORWARD)

    # Have to copy the array because _getArray is reference memory that PETSc will destroy in a moment
    serialized_array = copy(_getArray(serialized_vec))

    ccall((:VecScatterDestroy, library), PetscErrorCode, (Ref{VecScatter},), scatter)
    ccall((:VecDestroy, library), PetscErrorCode, (Ref{Vec},), serialized_vec.vec)

    return serialized_array
end

#### AbstractArray Interface Definitions ###

import Base.linearindexing

"""
    PETSc Vectors are inherently 1D
"""
function linearindexing(vec::PetscVecBase)
    return Base.LinearFast()
end

import Base.size

"""
    Returns the _global_ size of the vector
"""
function size(vec::PetscVecBase)
    N = Ref{PetscInt}(0)

    ccall((:VecGetSize, library), PetscErrorCode, (Vec, Ref{PetscInt}), vec.vec[], N)

    return (N[])
end

import Base.setindex!

"""
    Sets the value at i
"""
function setindex!(vec::PetscVecBase, v, i)
    # Copy out the values
    val = (Float64)[v_val for v_val in v]

    # Call the specialization below
    setindex!(vec, val, i)
end

"""
    Sets the value at i,j.

    Specialization for when v is already an array of Float64 (faster because we don't need to copy it)
"""
function setindex!(vec::PetscVecBase, v::Array{Float64}, i)
    i_ind = (PetscInt)[i_val-1 for i_val in i]

    @assert length(v) == length(i_ind)

    ccall((:VecSetValues, library), PetscErrorCode, (Vec, PetscInt, Ptr{PetscInt}, Ptr{PetscScalar}, InsertMode), vec.vec[], length(i_ind), i_ind, v, INSERT_VALUES)
end

"""
    Don't do this
"""
function setindex!(vec::PetscVecBase, v, i, j)
    error("Attempt to index PetscVecBasetor using multiple dimensions!")
end

import Base.getindex

"""
    Don't do this either
"""
function getindex(vec::PetscVecBase, i, j)
    error("Attempt to index PetscVecBasetor using multiple dimensions!")
end

"""
    Proper getter for entries from the vector for integer indices
"""
function getindex{T<:Integer}(vec::PetscVecBase, i::T)
    # Don't forget about 1-based indexing...
    i_ind = (PetscInt)[i-1]

    get_vals = Array{Float64}(1)

    ccall((:VecGetValues, library), PetscErrorCode, (Vec, PetscInt, Ptr{PetscInt}, Ref{PetscScalar}), vec.vec[], 1, i_ind, get_vals)

    return get_vals[1]
end

"""
    Proper getter for entries from the vector
"""
function getindex(vec::PetscVecBase, i)
    i_ind = (PetscInt)[i_val-1 for i_val in i]

    get_vals = Array{Float64}(length(i_ind))

    ccall((:VecGetValues, library), PetscErrorCode, (Vec, PetscInt, Ptr{PetscInt}, Ref{PetscScalar}), vec.vec[], length(i_ind), i_ind, get_vals)

    return get_vals
end

"""
    Helper function for ghosted vector indices
"""
function _getindices(vec::GhostedPetscVec, indices)
    raw_indices = Array{PetscInt}(length(indices))

    for i in 1:length(indices)
        index = indices[i]
        if vec.first_local_index <= index && index <= vec.last_local_index # Within the local portion of the vector
            raw_indices[i] = (index - vec.first_local_index) + 1
        else # Within the ghosted part
            raw_indices[i] = vec.global_to_local_map[index]
        end
    end

    return raw_indices
end

"""
    Proper getter for entries from the vector for integer indices for Ghosted Vectors
"""
function getindex{T<:Integer}(vec::GhostedPetscVec, i::T)
    if !vec.raw_array_present
        _getArray(vec)
    end

    return vec.raw_array[_getindices(vec, (PetscInt)[i])[1]]
end

"""
    Proper getter for entries from the vector for Ghosted Vectors
"""
function getindex(vec::GhostedPetscVec, i)
    if !vec.raw_array_present
        _getArray(vec)
    end

    return vec.raw_array[_getindices(vec, i)]
end


########## Private stuff

"""
    PRIVATE: Used internally.  Don't use.
"""
function _getArray(vec::PetscVecBase)
    raw_data = Ref{Ptr{PetscScalar}}()
    ccall((:VecGetArray, library), PetscErrorCode, (Vec, Ref{Ptr{PetscScalar}}), vec.vec[], raw_data)

    local_size = Ref{PetscInt}()
    ccall((:VecGetLocalSize, library), PetscErrorCode, (Vec, Ref{PetscInt}), vec.vec[], local_size)

    return unsafe_wrap(Array, raw_data[], local_size[], false)
end

"""
    PRIVATE: Used internally.  Don't use.
"""
function _getArray(vec::GhostedPetscVec)
    if !vec.raw_array_present
        vec.local_form = PetscVec("local_form")
        ccall((:VecGhostGetLocalForm, library), PetscErrorCode, (Vec, Ref{Vec}), vec.vec[], vec.local_form.vec)

        vec.raw_array = _getArray(vec.local_form)

        vec.raw_array_present = true
    end

    return vec.raw_array
end

import Base.unsafe_convert

"""
    PRIVATE: Used internally.  Don't use.
"""
function _restoreArray(vec::PetscVecBase, raw_data::Array{PetscScalar})
    # This mess is required because PETSc is expecting a PetscScalar** and Julia won't automatically
    # convert the array to that
    pointer = Ref{Ptr{PetscScalar}}()
    pointer[] = unsafe_convert(Ptr{PetscScalar}, raw_data)
    ccall((:VecRestoreArray, library), PetscErrorCode, (Vec, Ref{Ptr{PetscScalar}}), vec.vec[], pointer)
end

"""
    PRIVATE: Used internally.  Don't use.
"""
function _restoreArray(vec::GhostedPetscVec)
    if vec.raw_array_present
        _restoreArray(vec.local_form, vec.raw_array)
        ccall((:VecGhostRestoreLocalForm, library), PetscErrorCode, (Vec, Ref{Vec}), vec.vec[], vec.local_form.vec)
        vec.raw_array_present = false
    end
end
