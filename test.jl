using MiniPETSc

vec = PetscVec()

setSize!(vec, n_local=(Int32)(3))

vec[2] = 3.2

assemble!(vec)

viewVec(vec)

println(vec[2])

println(vec[1:2])
