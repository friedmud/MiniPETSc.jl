@testset "Vec.jl" begin
    begin
        vec = PetscVec()

        setSize!(vec, n_local=(Int32)(4))
        @test vec.sized

        # Test individual assignment
        vec[2] = 1.2

        assemble!(vec)

        @test size(vec) == (4)

        @test vec[2] == 1.2
    end

    begin
        vec = PetscVec()

        setSize!(vec, n_local=(Int32)(4))
        @test vec.sized

        # Test range assignment
        vec[1:2] = (Float64)[1 2]

        assemble!(vec)

        @test size(vec) == (4)
        @test vec[1:2] == (Float64)[1,2]
    end

    begin
        vec = PetscVec()

        setSize!(vec, n_local=(Int32)(4))
        @test vec.sized

        # Test Vector Assignment
        vec[[1,3]] = (Float64)[1 2]

        assemble!(vec)

        @test size(vec) == (4)
        @test vec[1:3] == (Float64)[1,0,2]
    end
end
