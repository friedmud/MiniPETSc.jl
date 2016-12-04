# Note: some definitions in this file come from PETSc.jl

typealias PetscErrorCode Cint
typealias comm_type MPI.CComm

typealias Mat Ptr{Void}

typealias PetscViewer Ptr{Void}

typealias PetscInt Int32
typealias PetscScalar Float64
typealias PetscBool UInt32

const PETSC_FALSE = (UInt32)(0)
const PETSC_TRUE = (UInt32)(1)
const PETSC_NULL = C_NULL
const PETSC_IGNORE = C_NULL
const PETSC_DECIDE = (Int32)(-1)
const PETSC_DETERMINE = PETSC_DECIDE
const PETSC_DEFAULT = (Int32)(-2)

typealias MatType Ptr{UInt8}
const MATAIJ = "aij"

typealias MatAssemblyType UInt32
const MAT_FINAL_ASSEMBLY = (UInt32)(0)

typealias InsertMode UInt32
const NOT_SET_VALUES = (UInt32)(0)
const INSERT_VALUES = (UInt32)(1)
const ADD_VALUES = (UInt32)(2)
const MAX_VALUES = (UInt32)(3)
const INSERT_ALL_VALUES = (UInt32)(4)
const ADD_ALL_VALUES = (UInt32)(5)
const INSERT_BC_VALUES = (UInt32)(6)
const ADD_BC_VALUES = (UInt32)(7)

typealias MatOption Cint
const MAT_OPTION_MIN = (Int32)(-5)
const MAT_NEW_NONZERO_LOCATION_ERR = (Int32)(-4)
const MAT_UNUSED_NONZERO_LOCATION_ERR = (Int32)(-3)
const MAT_NEW_NONZERO_ALLOCATION_ERR = (Int32)(-2)
const MAT_ROW_ORIENTED = (Int32)(-1)
const MAT_SYMMETRIC = (Int32)(1)
const MAT_STRUCTURALLY_SYMMETRIC = (Int32)(2)
const MAT_NEW_DIAGONALS = (Int32)(3)
const MAT_IGNORE_OFF_PROC_ENTRIES = (Int32)(4)
const MAT_USE_HASH_TABLE = (Int32)(5)
const MAT_KEEP_NONZERO_PATTERN = (Int32)(6)
const MAT_IGNORE_ZERO_ENTRIES = (Int32)(7)
const MAT_USE_INODES = (Int32)(8)
const MAT_HERMITIAN = (Int32)(9)
const MAT_SYMMETRY_ETERNAL = (Int32)(10)
const MAT_DUMMY = (Int32)(11)
const MAT_IGNORE_LOWER_TRIANGULAR = (Int32)(12)
const MAT_ERROR_LOWER_TRIANGULAR = (Int32)(13)
const MAT_GETROW_UPPERTRIANGULAR = (Int32)(14)
const MAT_SPD = (Int32)(15)
const MAT_NO_OFF_PROC_ZERO_ROWS = (Int32)(16)
const MAT_NO_OFF_PROC_ENTRIES = (Int32)(17)
const MAT_NEW_NONZERO_LOCATIONS = (Int32)(18)
const MAT_OPTION_MAX = (Int32)(19)



typealias Vec Ptr{Void}
typealias VecType Ptr{UInt8}
const VECMPI = "mpi"

typealias ScatterMode UInt32
const SCATTER_FORWARD = (UInt32)(0)
const SCATTER_REVERSE = (UInt32)(1)
const SCATTER_FORWARD_LOCAL = (UInt32)(2)
const SCATTER_REVERSE_LOCAL = (UInt32)(3)
const SCATTER_LOCAL = (UInt32)(2)

typealias KSP Ptr{Void}

typealias KSPType Ptr{UInt8}
const KSPRICHARDSON = "richardson"
const KSPCHEBYSHEV = "chebyshev"
const KSPCG = "cg"
const KSPGROPPCG = "groppcg"
const KSPPIPECG = "pipecg"
const KSPCGNE = "cgne"
const KSPNASH = "nash"
const KSPSTCG = "stcg"
const KSPGLTR = "gltr"
const KSPFCG = "fcg"
const KSPGMRES = "gmres"
const KSPFGMRES = "fgmres"
const KSPLGMRES = "lgmres"
const KSPDGMRES = "dgmres"
const KSPPGMRES = "pgmres"
const KSPTCQMR = "tcqmr"
const KSPBCGS = "bcgs"
const KSPIBCGS = "ibcgs"
const KSPFBCGS = "fbcgs"
const KSPFBCGSR = "fbcgsr"
const KSPBCGSL = "bcgsl"
const KSPCGS = "cgs"
const KSPTFQMR = "tfqmr"
const KSPCR = "cr"
const KSPPIPECR = "pipecr"
const KSPLSQR = "lsqr"
const KSPPREONLY = "preonly"
const KSPQCG = "qcg"
const KSPBICG = "bicg"
const KSPMINRES = "minres"
const KSPSYMMLQ = "symmlq"
const KSPLCD = "lcd"
const KSPPYTHON = "python"
const KSPGCR = "gcr"


typealias ISLocalToGlobalMapping Ptr{Void}
