
module MiniPETSc

using MPI

const library = "/opt/moose/petsc/mpich_petsc-3.6.1/clang-opt-superlu/lib/libpetsc"

include("PetscTypes.jl")

args = vcat("julia", ARGS)
nargs = length(args)
ccall((:PetscInitializeNoPointers, library), PetscErrorCode, (Cint, Ptr{Ptr{UInt8}}, Cstring, Cstring), nargs, args, C_NULL, C_NULL)

include("Mat.jl")
export PetscMat
export setSize!
export setPreallocation!
export assemble!
export viewMat

include("Vec.jl")
export PetscVec
export setSize!
export assemble!
export viewVec

include("KSP.jl")
export PetscKSP
export setOperators
export solve!

end
