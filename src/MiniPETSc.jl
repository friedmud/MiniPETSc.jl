
module MiniPETSc

using MPI

const library = "/opt/moose/petsc/mpich_petsc-3.6.1/clang-opt-superlu/lib/libpetsc"

include("PetscTypes.jl")

ccall((:PetscInitializeNoArguments, library), PetscErrorCode, ())

include("Mat.jl")

export PetscMat
export setSize!
export setPreallocation!
export assemble!

end
