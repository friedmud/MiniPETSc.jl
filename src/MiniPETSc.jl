__precompile__()

module MiniPETSc

using MPI

const library = "/opt/moose/petsc/mpich_petsc-3.6.1/clang-opt-superlu/lib/libpetsc"

include("PetscTypes.jl")

function __init__()
    args = vcat("julia", ARGS)
    nargs = length(args)
    ccall((:PetscInitializeNoPointers, library), PetscErrorCode, (Cint, Ptr{Ptr{UInt8}}, Cstring, Cstring), nargs, args, C_NULL, C_NULL)
end

# Cleanup at the end
atexit(() -> ccall((:PetscFinalize, library), PetscErrorCode, ()))

export PetscMat
export setSize!
export setPreallocation!
export assemble!
export viewMat
export zero!
export zeroRows!

export PetscVec
export GhostedPetscVec
export setSize!
export assemble!
export viewVec
export plusEquals!
export zero!
export copy!
export serializeToZero

import Base.scale!

export scale!

export PetscKSP
export setOperators
export solve!


include("Mat.jl")
include("Vec.jl")
include("KSP.jl")


end
