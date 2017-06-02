MODULE FVTypes
use decimal
IMPLICIT NONE
  ENUM, bind(c)
        ENUMERATOR :: SSPRK22
        ENUMERATOR :: FORWARD_EULER
        ENUMERATOR :: RK4
        ENUMERATOR :: SSPRRK33
  END ENUM
  ENUM, bind(c)
        ENUMERATOR :: ZERO_FLUX
        ENUMERATOR :: PERIODIC
  END ENUM
    abstract interface
      function AbstractFlux(phi) result(f)
          import  :: dp
          real(kind = dp), intent(in) :: phi(:)
          real(kind = dp) :: f(SIZE(phi,1))
      end function AbstractFlux
      function AbstractJacF(phi) result(Jf)
          import  :: dp
          real(kind = dp), intent(in) :: phi(:)
          real(kind = dp) :: Jf(SIZE(phi,1),SIZE(phi,1))
      end function AbstractJacF
      function AbstractDiffMat(phi) result(k)
          import :: dp
          real(kind = dp), intent(in) :: phi(:)
          real(kind = dp) :: k(SIZE(phi,1), SIZE(phi,1))
      end function AbstractDiffMat
    end interface
!Mesh types
  type, public :: Uniform1DMesh
      integer        :: N
      REAL(KIND=dp), ALLOCATABLE  :: x(:)
      real(kind=dp)  :: dx
      integer        :: bdtype
      CONTAINS
      procedure :: initialize => init_uniform1d
  end type Uniform1DMesh
!Problem Type
  type, public :: CLS1DDiffusionProblem
      type(Uniform1DMesh)     :: mesh
      real(kind=dp)           :: Tend
      integer                 :: M
      REAL(KIND=dp), ALLOCATABLE  :: u0(:,:)
      REAL(KIND=dp), ALLOCATABLE  :: uu(:,:)
      procedure(Abstractflux),pointer,nopass :: f
      procedure(AbstractJacF),pointer,nopass :: Jf
      procedure(AbstractDiffMat),pointer,nopass :: K
      CONTAINS
      procedure :: initialize => init_1DDiffProblem
  end type CLS1DDiffusionProblem

  type, public :: CLS1DProblem
      type(Uniform1DMesh)     :: mesh
      real(kind=dp)           :: Tend
      integer                 :: M
      REAL(KIND=dp), ALLOCATABLE  :: u0(:,:)
      REAL(KIND=dp), ALLOCATABLE  :: uu(:,:)
      procedure(Abstractflux),pointer,nopass :: f
      procedure(AbstractJacF),pointer,nopass :: Jf
      CONTAINS
      procedure :: initialize => init_1DProblem
  end type CLS1DProblem

!Algorithms type

  type, abstract, public :: FVAlgorithm
  CONTAINS
      procedure(abstractGetStartMessage), deferred :: getStartMessage
  end type FVAlgorithm

  type, abstract, public, extends(FVAlgorithm) :: FVDiff1DAlgorithm
    CONTAINS
      procedure(abstractUpdateDiffRHS), deferred :: update
  end type FVDiff1DAlgorithm

  type, abstract, public, extends(FVAlgorithm) :: FV1DAlgorithm
    CONTAINS
      procedure(abstractUpdateRHS), deferred :: update
  end type FV1DAlgorithm
  
  abstract interface
      subroutine abstractUpdateDiffRHS(alg, rhs, uold, dt, prob)
          import :: dp
          import FVDiff1DAlgorithm
          import CLS1DDiffusionProblem
          CLASS(FVDiff1DAlgorithm)  :: alg
          real(kind = dp), intent(in) :: uold(:,:)
          real(kind = dp) :: rhs(:,:), dt
          TYPE(CLS1DDiffusionProblem) :: prob
      end subroutine abstractUpdateDiffRHS
      subroutine abstractUpdateRHS(alg, rhs, uold, dt, prob)
          import :: dp
          import FV1DAlgorithm
          import CLS1DProblem
          CLASS(FV1DAlgorithm)  :: alg
          real(kind = dp), intent(in) :: uold(:,:)
          real(kind = dp) :: rhs(:,:), dt
          TYPE(CLS1DProblem) :: prob
      end subroutine abstractUpdateRHS
      function abstractGetStartMessage(alg) result(message)
            import FVAlgorithm
            CLASS(FVAlgorithm)  :: alg
            CHARACTER(LEN=32)             :: message
      end function abstractGetStartMessage
end interface

  CONTAINS
  !Mesh types
  subroutine init_uniform1d(mesh, N, xinit, xend, bdtype)
      CLASS(Uniform1DMesh)    :: mesh
      integer           :: N, bdtype, i
      real(kind=dp)     :: xinit, xend, dx, L
      REAL(KIND=dp), ALLOCATABLE  :: xx(:)
      !========================
      L = xend-xinit
      dx = L/N
      ALLOCATE(mesh%x(N))
      mesh%x = 0.0_dp;
      mesh%x = (/(i*dx+dx/2+xinit,i=0, N-1)/)   
      mesh%N = N;mesh%dx = dx; mesh%bdtype = bdtype
  end subroutine init_uniform1d
  ! Problem type
  subroutine init_1DDiffProblem(problem, mesh, u0, M, Tend, Flux, JacF, DiffMat)
      CLASS(CLS1DDiffusionProblem)  :: problem
      type(Uniform1DMesh)           :: mesh
      REAL(KIND=dp)                 :: u0(:,:), Tend
      integer           :: M,N
      procedure(Abstractflux) :: Flux
      procedure(AbstractJacF) :: JacF
      procedure(AbstractDiffMat) :: DiffMat
      !========================
      N = mesh%N
      ALLOCATE(problem%uu(N,M), problem%u0(N,M))
      problem%M = M
      problem%uu = u0
      problem%u0 = u0
      problem%Tend = Tend
      problem%mesh = mesh
      problem%f => Flux
      problem%Jf => JacF
      problem%K => DiffMat
  end subroutine init_1DDiffProblem
    subroutine init_1DProblem(problem, mesh, u0, M, Tend, Flux, JacF)
      CLASS(CLS1DProblem)  :: problem
      type(Uniform1DMesh)           :: mesh
      REAL(KIND=dp)                 :: u0(:,:), Tend
      integer           :: M,N
      procedure(Abstractflux) :: Flux
      procedure(AbstractJacF) :: JacF
      !========================
      N = mesh%N
      ALLOCATE(problem%uu(N,M), problem%u0(N,M))
      problem%M = M
      problem%uu = u0
      problem%u0 = u0
      problem%Tend = Tend
      problem%mesh = mesh
      problem%f => Flux
      problem%Jf => JacF
  end subroutine init_1DProblem

END MODULE FVTypes