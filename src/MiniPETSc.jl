__precompile__()

module MiniPETSc

using Reexport

@reexport using MPI

const library = string(ENV["PETSC_DIR"],"/lib/libpetsc")

include("PetscTypes.jl")

function finalize()
    ccall((:PetscFinalize, library), PetscErrorCode, ())
end

function __init__()
    args = vcat("julia", ARGS)
    nargs = length(args)
    ccall((:PetscInitializeNoPointers, library), PetscErrorCode, (Cint, Ptr{Ptr{UInt8}}, Cstring, Cstring), nargs, args, C_NULL, C_NULL)

    # Cleanup at the end
    atexit(finalize)
end

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
