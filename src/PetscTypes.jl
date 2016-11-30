typealias PetscErrorCode Cint
typealias comm_type MPI.CComm

typealias Mat Ptr{Void}

typealias PetscViewer Ptr{Void}

const PETSC_NULL = C_NULL
const PETSC_IGNORE = C_NULL
const PETSC_DECIDE = -1
const PETSC_DETERMINE = PETSC_DECIDE
const PETSC_DEFAULT = -2

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
