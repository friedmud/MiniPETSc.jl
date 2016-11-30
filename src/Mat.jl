include("PetscTypes.jl")

const library = "/opt/moose/petsc/mpich_petsc-3.6.1/clang-opt-superlu/lib/libpetsc"

mat = Ref{Mat}()

ccall((:PetscInitializeNoArguments, library), PetscErrorCode, ())

ccall((:MatCreate, library), PetscErrorCode, (comm_type, Ref{Mat}), MPI.COMM_WORLD, mat)

const mat_type = "aij"

ccall((:MatSetType, library), PetscErrorCode, (Mat, Ptr{UInt8}), mat[], mat_type)

println(mat)

ccall((:MatSetSizes, library), PetscErrorCode, (Mat, Int32, Int32, Int32, Int32), mat[], 4, 4, 4, 4)

nnz = (Int32)[4,4,4,4]

onnz = (Int32)[0,0,0,0]

ccall((:MatSeqAIJSetPreallocation, library), PetscErrorCode, (Mat, Int32, Ptr{Int32}), mat[], PETSC_DEFAULT, nnz)
#ccall((:MatSeqAIJSetPreallocation, library), PetscErrorCode, (Mat, Int32, Ptr{Int32}), mat[], 4, C_NULL)

# PetscErrorCode  MatMPIAIJSetPreallocation                  (Mat B,PetscInt d_nz,const PetscInt d_nnz[],PetscInt o_nz,const PetscInt o_nnz[])
ccall((:MatMPIAIJSetPreallocation, library), PetscErrorCode, (Mat,  Int32,        Ptr{Int32},            Int32,        Ptr{Int32}), mat[], PETSC_DEFAULT, nnz, PETSC_DEFAULT, onnz)

i = (Int32)[0, 1, 2, 3]
j = (Int32)[0, 1, 2, 3]
val = (Float64)[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]

ccall((:MatSetValues, library), PetscErrorCode, (Mat, Int32, Ptr{Int32}, Int32, Ptr{Int32}, Ptr{Float64}, InsertMode), mat[], length(i), i, length(j), j, val, INSERT_VALUES)

ccall((:MatAssemblyBegin, library), PetscErrorCode, (Mat, UInt32), mat[], MAT_FINAL_ASSEMBLY)
ccall((:MatAssemblyEnd, library), PetscErrorCode, (Mat, UInt32), mat[], MAT_FINAL_ASSEMBLY)

M = Ref{Int32}(0)
N = Ref{Int32}(0)

ccall((:MatGetSize, library), PetscErrorCode, (Mat, Ref{Int32}, Ref{Int32}), mat[], M, N)

m = Ref{Int32}(0)
n = Ref{Int32}(0)

ccall((:MatGetLocalSize, library), PetscErrorCode, (Mat, Ref{Int32}, Ref{Int32}), mat[], m, n)

println(M[], ", ", N[])
println(m[], ", ", n[])

#ccall((:MatSetValue, library), PetscErrorCode, (Mat, Int32, Int32, Float64, InsertMode), mat[], 0, 0, 1, INSERT_VALUES)

viewer = ccall((:PETSC_VIEWER_STDOUT_, library), PetscViewer, (comm_type,), MPI.COMM_WORLD)

ccall((:MatView, library), PetscErrorCode, (Mat, PetscViewer), mat[], viewer)
