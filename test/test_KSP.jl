@testset "KSP.jl" begin
    begin
        vec = PetscVec()
        setSize!(vec, n_local=(Int32)(3))
        vec[1:3] = (Float64)[1, 2, 3]
        assemble!(vec)

        sol = PetscVec()
        setSize!(sol, n_local=(Int32)(3))
        assemble!(sol)

        mat = PetscMat()
        setSize!(mat, m_local=(Int32)(3), n_local=(Int32)(3))
        setPreallocation!(mat, (Int32)[1,1,1], (Int32)[])

        mat[1,1] = (Float64)(1)
        mat[2,2] = (Float64)(2)
        mat[3,3] = (Float64)(3)

        assemble!(mat)

        ksp = PetscKSP()

        setOperators(ksp, mat)

        solve!(ksp, vec, sol)

        for val in sol[1:3]
            @test abs(sol[1]-1.0) < 1e-9
        end
    end
end
