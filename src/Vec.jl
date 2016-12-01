"""
    A PETSc Vec wrapper.
"""
type PetscVec <: AbstractArray{PetscScalar}

    " The pointer to the PETSc Vec object "
    vec::Ref{Vec}

    " Whether or not a size has been set by calling setSize() "
    sized::Bool

    " Whether or not the vecrix has ever been assembled (Note: the vecrix might currently NOT be assembled) "
    assembled::Bool

    function PetscVec()
        vec = Ref{Vec}()
        ccall((:VecCreate, library), PetscErrorCode, (comm_type, Ref{Vec}), MPI.COMM_WORLD, vec)
        ccall((:VecSetType, library), PetscErrorCode, (Vec, VecType), vec[], VECMPI)
        new(vec, false, false)
    end
end

"""
    Set up the size of a PetscVec

    Note: This MUST be called before setting/getting values!
"""
function setSize!(vec::PetscVec; n_local::PetscInt=PETSC_DECIDE, n_global::PetscInt=PETSC_DETERMINE)
    @assert !vec.sized

    # Must provide _some_ size!
    @assert n_local != PETSC_DECIDE || n_global != PETSC_DETERMINE

    ccall((:VecSetSizes, library), PetscErrorCode, (Vec, PetscInt, PetscInt), vec.vec[], n_local, n_global)

    vec.sized = true
end

"""
    Must be called after setting/adding values to construct the vector
"""
function assemble!(vec::PetscVec)
    @assert vec.sized

    ccall((:VecAssemblyBegin, library), PetscErrorCode, (Vec,), vec.vec[])
    ccall((:VecAssemblyEnd, library), PetscErrorCode, (Vec,), vec.vec[])

    vec.assembled = true
end

"""
    Use PETSc viewer to print out the vector
"""
function viewVec(vec::PetscVec)
    @assert vec.sized
    @assert vec.assembled

    viewer = ccall((:PETSC_VIEWER_STDOUT_, library), PetscViewer, (comm_type,), MPI.COMM_WORLD)
    ccall((:VecView, library), PetscErrorCode, (Vec, PetscViewer), vec.vec[], viewer)
end

"""
    Does vec[i] += v
"""
function plusEquals!(vec::PetscVec, v::Array{Float64}, i)
    i_ind = (PetscInt)[i_val-1 for i_val in i]

    @assert length(v) == length(i_ind)

    ccall((:VecSetValues, library), PetscErrorCode, (Vec, PetscInt, Ptr{PetscInt}, Ptr{PetscScalar}, InsertMode), vec.vec[], length(i_ind), i_ind, v, ADD_VALUES)
end

#### AbstractArray Interface Definitions ###

import Base.linearindexing

"""
    PETSc Vectors are inherently 1D
"""
function linearindexing(vec::PetscVec)
    return Base.LinearFast()
end

import Base.size

"""
    Returns the _global_ size of the vector
"""
function size(vec::PetscVec)
    N = Ref{PetscInt}(0)

    ccall((:VecGetSize, library), PetscErrorCode, (Vec, Ref{PetscInt}), vec.vec[], N)

    return (N[])
end

import Base.setindex!

"""
    Sets the value at i
"""
function setindex!(vec::PetscVec, v, i)
    # Copy out the values
    val = (Float64)[v_val for v_val in v]

    # Call the specialization below
    setindex!(vec, val, i)
end

"""
    Sets the value at i,j.

    Specialization for when v is already an array of Float64 (faster because we don't need to copy it)
"""
function setindex!(vec::PetscVec, v::Array{Float64}, i)
    i_ind = (PetscInt)[i_val-1 for i_val in i]

    @assert length(v) == length(i_ind)

    ccall((:VecSetValues, library), PetscErrorCode, (Vec, PetscInt, Ptr{PetscInt}, Ptr{PetscScalar}, InsertMode), vec.vec[], length(i_ind), i_ind, v, INSERT_VALUES)
end

"""
    Don't do this
"""
function setindex!(vec::PetscVec, v, i, j)
    error("Attempt to index PetscVector using multiple dimensions!")
end

import Base.getindex

"""
    Don't do this either
"""
function getindex(vec::PetscVec, i, j)
    error("Attempt to index PetscVector using multiple dimensions!")
end

"""
    Proper getter for entries from the vector for integer indices
"""
function getindex{T<:Integer}(vec::PetscVec, i::T)
    # Don't forget about 1-based indexing...
    i_ind = (PetscInt)[i-1]

    get_vals = Array{Float64}(1)

    ccall((:VecGetValues, library), PetscErrorCode, (Vec, PetscInt, Ptr{PetscInt}, Ref{PetscScalar}), vec.vec[], 1, i_ind, get_vals)

    return get_vals[1]
end

"""
    Proper getter for entries from the vector
"""
function getindex(vec::PetscVec, i)
    i_ind = (PetscInt)[i_val-1 for i_val in i]

    get_vals = Array{Float64}(length(i_ind))

    ccall((:VecGetValues, library), PetscErrorCode, (Vec, PetscInt, Ptr{PetscInt}, Ref{PetscScalar}), vec.vec[], length(i_ind), i_ind, get_vals)

    return get_vals
end
