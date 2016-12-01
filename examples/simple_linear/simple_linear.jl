using MiniPETSc

vec = PetscVec()
setSize!(vec, n_local=(Int32)(3))
vec[1:3] = (Float64)[1, 2, 3]
assemble!(vec)
viewVec(vec)

sol = PetscVec()
setSize!(sol, n_local=(Int32)(3))
assemble!(sol)
viewVec(sol)

mat = PetscMat()
setSize!(mat, m_local=(Int32)(3), n_local=(Int32)(3))
setPreallocation!(mat, (Int32)[1,1,1], (Int32)[])

mat[1,1] = (Float64)(1)
mat[2,2] = (Float64)(2)
mat[3,3] = (Float64)(3)

assemble!(mat)
viewMat(mat)

ksp = PetscKSP()

setOperators(ksp, mat)

solve!(ksp, vec, sol)

viewVec(sol)
