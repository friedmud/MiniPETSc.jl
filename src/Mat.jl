"""
    A PETSc Mat wrapper.
"""
type PetscMat <: AbstractMatrix{PetscScalar}

    " The pointer to the PETSc Mat object "
    mat::Ref{Mat}

    " Whether or not a size has been set by calling setSize() "
    sized::Bool

    " Whether or not preallocation has been done by calling setPreallocation() "
    preallocated::Bool

    function PetscMat()
        mat = Ref{Mat}()
        ccall((:MatCreate, library), PetscErrorCode, (comm_type, Ref{Mat}), MPI.COMM_WORLD, mat)
        ccall((:MatSetType, library), PetscErrorCode, (Mat, MatType), mat[], MATAIJ)
        new(mat, false, false)
    end
end

"""
    Set up the size of a PetscMat

    Note: This MUST be called before setting Pre-allocation and _definitely_ must be called before setting/getting values!
"""
function setSize!(mat::PetscMat; m_local::PetscInt=PETSC_DECIDE, n_local::PetscInt=PETSC_DECIDE, m_global::PetscInt=PETSC_DETERMINE, n_global::PetscInt=PETSC_DETERMINE)
    @assert !mat.sized

    # Must provide _some_ size!
    @assert (m_local != PETSC_DECIDE && n_local != PETSC_DECIDE) || (m_global != PETSC_DETERMINE && n_global != PETSC_DETERMINE)

    ccall((:MatSetSizes, library), PetscErrorCode, (Mat, PetscInt, PetscInt, PetscInt, PetscInt), mat.mat[], m_local, n_local, m_global, n_global)

    mat.sized = true
end

"""
    Set the preallocation for storage in each row.

    Note: Should be called _after_ setSize!
"""
function setPreallocation!(mat::PetscMat, local_nonzeros_per_row::Array{PetscInt}, off_processor_nonzeros_per_row::Array{PetscInt})
    @assert mat.sized
    @assert !mat.preallocated

    # The preallocation is done for both serial _and_ parallel to make this capable of doing both (this is the suggestion in the PETSc docs)
    ccall((:MatSeqAIJSetPreallocation, library), PetscErrorCode, (Mat, PetscInt, Ptr{PetscInt}),
          mat.mat[], PETSC_DEFAULT, local_nonzeros_per_row)

    ccall((:MatMPIAIJSetPreallocation, library), PetscErrorCode, (Mat, PetscInt, Ptr{PetscInt}, PetscInt, Ptr{PetscInt}),
          mat.mat[], PETSC_DEFAULT, local_nonzeros_per_row, PETSC_DEFAULT, off_processor_nonzeros_per_row)

    mat.preallocated = true
end

"""
    Must be called after setting/adding values to construct the matrix
"""
function assemble!(mat::PetscMat)
    @assert mat.sized
    @assert mat.preallocated

    ccall((:MatAssemblyBegin, library), PetscErrorCode, (Mat, MatAssemblyType), mat.mat[], MAT_FINAL_ASSEMBLY)
    ccall((:MatAssemblyEnd, library), PetscErrorCode, (Mat, MatAssemblyType), mat.mat[], MAT_FINAL_ASSEMBLY)
end

#### AbstractArray Interface Definitions ###

import Base.linearindexing

"""
    PETSc Matrices are inherently 2D
"""
function linearindexing(mat::PetscMat)
    return Base.LinearSlow()
end

import Base.size

"""
    Returns the _global_ size of the matrix
"""
function size(mat::PetscMat)
    M = Ref{PetscInt}(0)
    N = Ref{PetscInt}(0)

    ccall((:MatGetSize, library), PetscErrorCode, (Mat, Ref{PetscInt}, Ref{PetscInt}), mat.mat[], M, N)

    return (M, N)
end

import Base.setindex!

"""
    Sets the value at i,j
"""
function setindex!(mat::PetscMat, v, i, j)
    println("setindex!(mat::PetscMat, v, i, j)")

    # Copy out the values
    val = (Float64)[v_val for v_val in v]

    # Call the specialization below
    setindex!(mat, val, i, j)
end

"""
    Sets the value at i,j.

    Specialization for when v is already an array of Float64 (faster because we don't need to copy it)
"""
function setindex!(mat::PetscMat, v::Array{Float64}, i, j)
    println("setindex!(mat::PetscMat, v::Array{Float64}, i, j)")

    # Convert the indices to 0-based indexing
    i_ind = (PetscInt)[i_val-1 for i_val in i]
    j_ind = (PetscInt)[j_val-1 for j_val in j]

    @assert length(v) == length(i_ind) * length(j_ind)

    ccall((:MatSetValues, library), PetscErrorCode, (Mat, PetscInt, Ptr{PetscInt}, PetscInt, Ptr{PetscInt}, Ptr{PetscScalar}, InsertMode), mat.mat[], length(i_ind), i_ind, length(j_ind), j_ind, v, INSERT_VALUES)
end

"""
    Don't do this
"""
function setindex!(mat::PetscMat, v, I)
    error("Attempt to index PetscMatrix using a single dimension!")
end

import Base.getindex

"""
    Don't do this either
"""
function getindex(mat::PetscMat, I)
    error("Attempt to index PetscMatrix using a single dimension!")
end

#m = Ref{PetscInt}(0)
#n = Ref{PetscInt}(0)

#ccall((:MatGetLocalSize, library), PetscErrorCode, (Mat, Ref{PetscInt}, Ref{PetscInt}), mat[], m, n)


#ccall((:MatSetValue, library), PetscErrorCode, (Mat, PetscInt, PetscInt, Float64, InsertMode), mat[], 0, 0, 1, INSERT_VALUES)

#viewer = ccall((:PETSC_VIEWER_STDOUT_, library), PetscViewer, (comm_type,), MPI.COMM_WORLD)
#ccall((:MatView, library), PetscErrorCode, (Mat, PetscViewer), mat[], viewer)
