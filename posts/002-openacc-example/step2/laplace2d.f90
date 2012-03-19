program laplace
  implicit none
  integer, parameter :: fp_kind=kind(1.0)
  integer, parameter :: n=4096, m=4096, iter_max=1000
  integer :: i, j, iter
  real(fp_kind), dimension (:,:), allocatable :: A, Anew
  real(fp_kind), dimension (:),   allocatable :: y0
  real(fp_kind) :: pi=2.0_fp_kind*asin(1.0_fp_kind), tol=1.0e-5_fp_kind, error=1.0_fp_kind
  real(fp_kind) :: start_time, stop_time

  allocate ( A(0:n-1,0:m-1), Anew(0:n-1,0:m-1) )
  allocate ( y0(0:m-1) )

  A = 0.0_fp_kind

  ! Set B.C.
  y0 = sin(pi* (/ (j,j=0,m-1) /) /(m-1))

  A(0,:)   = 0.0_fp_kind
  A(n-1,:) = 0.0_fp_kind
  A(:,0)   = y0
  A(:,m-1) = y0*exp(-pi)
   
  write(*,'(a,i5,a,i5,a)') 'Jacobi relaxation Calculation:', n, ' x', m, ' mesh'
 
  call cpu_time(start_time) 

  iter=0

!$omp parallel do shared(Anew)
  do i=1,m-1
    Anew(0,i)   = 0.0_fp_kind
    Anew(n-1,i) = 0.0_fp_kind
  end do
!$omp end parallel do

!$omp parallel do shared(Anew)
  do i=1,n-1
    Anew(i,0)   = y0(i)
    Anew(i,m-1) = y0(i)*exp(-pi)
  end do
!$omp end parallel do

!$acc data copy(A, Anew)
  do while ( error .gt. tol .and. iter .lt. iter_max )
    error=0.0_fp_kind

!$omp parallel do shared(m, n, Anew, A) reduction( max:error )
!$acc kernels
    do j=1,m-2
      do i=1,n-2
        Anew(i,j) = 0.25_fp_kind * ( A(i+1,j  ) + A(i-1,j  ) + &
                                     A(i  ,j-1) + A(i  ,j+1) )
        error = max( error, abs(Anew(i,j)-A(i,j)) )
      end do
    end do
!$acc end kernels
!$omp end parallel do

    if(mod(iter,100).eq.0 ) write(*,'(i5,f10.6)'), iter, error
    iter = iter +1

!$omp parallel do shared(m, n, Anew, A)
!$acc kernels
    do j=1,m-2
      do i=1,n-2
        A(i,j) = Anew(i,j)
      end do
    end do
!$acc end kernels
!$omp end parallel do


  end do
!$acc end data

  call cpu_time(stop_time) 
  write(*,'(a,f10.3,a)')  ' completed in ', stop_time-start_time, ' seconds'

  deallocate (A,Anew,y0)
end program laplace
