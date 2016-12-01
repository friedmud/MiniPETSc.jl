# Run using: mpiexec -n 2 julia parallel_solve.jl

using MiniPETSc

vec = PetscVec()

setSize!(vec, n_local=(Int32)(5), n_global=(Int32)(10))

if MPI.Comm_rank(MPI.COMM_WORLD) == 0
    vec[1:5] = (Float64)[1, 2, 3, 4, 5]
else
    vec[6:10] = (Float64)[6, 7, 8, 9, 10]
end

assemble!(vec)
viewVec(vec)

sol = PetscVec()
setSize!(sol, n_local=(Int32)(5), n_global=(Int32)(10))
assemble!(sol)
viewVec(sol)

mat = PetscMat()
setSize!(mat, m_local=(Int32)(5), n_local=(Int32)(5))
setPreallocation!(mat, (Int32)[1,1,1,1,1], (Int32)[0,0,0,0,0])

if MPI.Comm_rank(MPI.COMM_WORLD) == 0
    mat[1,1] = (Float64)(1)
    mat[2,2] = (Float64)(2)
    mat[3,3] = (Float64)(3)
    mat[4,4] = (Float64)(4)
    mat[5,5] = (Float64)(5)
else
    mat[6,6] = (Float64)(6)
    mat[7,7] = (Float64)(7)
    mat[8,8] = (Float64)(8)
    mat[9,9] = (Float64)(9)
    mat[10,10] = (Float64)(10)
end

assemble!(mat)
viewMat(mat)

ksp = PetscKSP()

setOperators(ksp, mat)

solve!(ksp, vec, sol)

viewVec(sol)
