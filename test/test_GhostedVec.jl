@testset "GhostedVec.jl" begin
    begin
        if MPI.Comm_size(MPI.COMM_WORLD) == 2
            if MPI.Comm_rank(MPI.COMM_WORLD) == 0
                vec = GhostedPetscVec([6,7], n_local=(Int32)(4))
                @test vec.first_local_index == 1
                @test vec.last_local_index == 4

                @test vec.global_to_local_map == Dict{Int32, Int32}(6 => 5, 7 => 6)

                @test vec.sized

                # # Test individual assignment
                vec[2] = 2.6

                assemble!(vec)

                @test size(vec) == 8

                @test vec[2] == 2.6

                @test vec[6] == 1.2

                vec[3] = 8.7

                assemble!(vec)

                @test vec[3] == 8.7
                @test vec[7] == 2.9
            else
                vec = GhostedPetscVec([1,2], n_local=(Int32)(4))

                @test vec.first_local_index == 5
                @test vec.last_local_index == 8

                @test vec.global_to_local_map == Dict{Int32, Int32}(1 => 5, 2 => 6)

                @test vec.sized

                # # Test individual assignment
                vec[6] = 1.2

                assemble!(vec)

                @test size(vec) == 8

                @test vec[6] == 1.2

                @test vec[2] == 2.6

                vec[7] = 2.9

                assemble!(vec)

                @test vec[7] == 2.9
            end

            if MPI.Comm_rank(MPI.COMM_WORLD) == 0
                vec = GhostedPetscVec([6,7], n_local=(Int32)(4))

                # Test Ranged assignment
                vec[1:2] = (Float64)[1 2]

                assemble!(vec)

                @test vec[1:2] == (Float64)[1,2]

                # Test Array access to ghosts
                @test vec[[1,6]] == [1,6]
            else
                vec = GhostedPetscVec([1,2], n_local=(Int32)(4))

                # Test Ranged assignment
                vec[6:7] = (Float64)[6 7]

                assemble!(vec)

                @test vec[6:7] == (Float64)[6,7]
            end
        end
    end


    # begin
    #     vec = GhostedPetscVec([], n_local=(Int32)(4))

    #     @test vec.sized

    #     # Test Vector Assignment
    #     vec[[1,3]] = (Float64)[1 2]

    #     assemble!(vec)

    #     @test size(vec) == (4)
    #     @test vec[1:3] == (Float64)[1,0,2]
    # end

    # begin
    #     vec = GhostedPetscVec([], n_local=(Int32)(3))
    #     vec[1:3] = (Float64)[1, 2, 3]
    #     assemble!(vec)

    #     # Test +=
    #     plusEquals!(vec, (Float64)[2, 3, 4], (Int32)[1,2,3])
    #     assemble!(vec)

    #     @test vec[1:3] == (Float64)[3, 5, 7]
    # end
end
