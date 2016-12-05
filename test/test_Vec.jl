@testset "Vec.jl" begin
    # begin
    #     vec = PetscVec()

    #     setSize!(vec, n_local=(Int32)(4))
    #     @test vec.sized

    #     # Test individual assignment
    #     vec[2] = 1.2

    #     assemble!(vec)

    #     @test size(vec) == (4)

    #     @test vec[2] == 1.2
    # end

    # begin
    #     vec = PetscVec()

    #     setSize!(vec, n_local=(Int32)(4))
    #     @test vec.sized

    #     # Test range assignment
    #     vec[1:2] = (Float64)[1 2]

    #     assemble!(vec)

    #     @test size(vec) == (4)
    #     @test vec[1:2] == (Float64)[1,2]
    # end

    # begin
    #     vec = PetscVec()

    #     setSize!(vec, n_local=(Int32)(4))
    #     @test vec.sized

    #     # Test Vector Assignment
    #     vec[[1,3]] = (Float64)[1 2]

    #     assemble!(vec)

    #     @test size(vec) == (4)
    #     @test vec[1:3] == (Float64)[1,0,2]
    # end

    # begin
    #     vec = PetscVec()
    #     setSize!(vec, n_local=(Int32)(3))
    #     vec[1:3] = (Float64)[1, 2, 3]
    #     assemble!(vec)

    #     # Test +=
    #     plusEquals!(vec, (Float64)[2, 3, 4], (Int32)[1,2,3])
    #     assemble!(vec)

    #     @test vec[1:3] == (Float64)[3, 5, 7]
    # end

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
    end
end
