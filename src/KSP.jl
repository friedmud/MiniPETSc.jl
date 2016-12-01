"""
    Krylov solver
"""
type PetscKSP
    ksp::Ref{KSP}

    function PetscKSP()
        ksp = Ref{KSP}()
        ccall((:KSPCreate, library), PetscErrorCode, (comm_type, Ref{KSP}), MPI.COMM_WORLD, ksp)
        new(ksp)
    end
end

"""
    Set the matrix to use (A)
"""
function setOperators(ksp::PetscKSP, mat::PetscMat)
    ccall((:KSPSetOperators, library), PetscErrorCode, (KSP, Mat, Mat), ksp.ksp[], mat.mat[], mat.mat[])
end

"""
    Solve the linear system

    Ax=b
"""
function solve!(ksp::PetscKSP, b::PetscVec, x::PetscVec)
    ccall((:KSPSolve, library), PetscErrorCode, (KSP, Vec, Vec), ksp.ksp[], b.vec[], x.vec[])
end
