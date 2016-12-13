using MiniPETSc

using Base.Test

if MPI.Comm_size(MPI.COMM_WORLD) == 1
    include("test_Mat.jl")
    include("test_Vec.jl")
    include("test_KSP.jl")
else
    include("test_GhostedVec.jl")
    include("test_parallel_Vec.jl")
end