using MPI

MPI.Init()

using MiniPETSc

using Base.Test

#include("test_Mat.jl")
#include("test_Vec.jl")
#include("test_KSP.jl")

include("test_GhostedVec.jl")

MPI.Finalize()