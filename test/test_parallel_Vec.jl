@testset "test_parallel_Vec.jl" begin
   if MPI.Comm_size(MPI.COMM_WORLD) == 2
        # Test serialization
        if MPI.Comm_rank(MPI.COMM_WORLD) == 0
            vec = PetscVec()
            setSize!(vec, n_local=(Int32)(3))

            vec[1:3] = [i for i in 1:3]

            assemble!(vec)

            @test serializeToZero(vec) == (Float64)[1., 2., 3., 4., 5., 6.]
        else
            vec = PetscVec()
            setSize!(vec, n_local=(Int32)(3))

            vec[4:6] = [i for i in 4:6]

            assemble!(vec)
            serializeToZero(vec)
        end

        # Test getArray and restoreArray
        if MPI.Comm_rank(MPI.COMM_WORLD) == 0
            vec = PetscVec()
            setSize!(vec, n_local=(Int32)(3))

            vec[1:3] = [i for i in 1:3]

            assemble!(vec)

            array = MiniPETSc._getArray(vec)
            MiniPETSc._restoreArray(vec, array)

            @test vec[1:3] == [i for i in 1:3]
        else
            vec = PetscVec()
            setSize!(vec, n_local=(Int32)(3))

            vec[4:6] = [i for i in 4:6]

            assemble!(vec)

            array = MiniPETSc._getArray(vec)
            MiniPETSc._restoreArray(vec, array)

            @test vec[4:6] == [i for i in 4:6]
        end
    end
end
