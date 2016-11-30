using MiniPETSc

mat = PetscMat()

setSize!(mat, m_local=(Int32)(3), n_local=(Int32)(3))

setPreallocation!(mat, (Int32)[2, 2, 2], (Int32)[])

mat[1,2] = 4
mat[1:2, 1:2] = [3,3,4,5]
mat[(Int32)[1,2], (Int32)[1,2]] = (Float64)[3,3,4,5]

assemble!(mat)
