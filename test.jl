using MiniPETSc

mat = PetscMat()

setSize!(mat, m_local=(Int32)(3), n_local=(Int32)(3))

setPreallocation!(mat, (Int32)[3, 3, 2], (Int32)[])

local_mat = (Float64)[1 2; 3 4; 5 6]

#mat[1,2] = 4
#mat[1:2, 1:2] = [3,3,4,5]
#mat[(Int32)[1,2], (Int32)[1,2]] = (Float64)[3,3,4,5]

mat[1:3, 1:2] = local_mat

assemble!(mat)

viewMat(mat)

println(mat[1:3,1:2])
