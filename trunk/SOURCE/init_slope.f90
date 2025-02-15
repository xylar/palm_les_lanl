!> @file init_slope.f90
!------------------------------------------------------------------------------!
! This file is part of the PALM model system.
!
! PALM is free software: you can redistribute it and/or modify it under the
! terms of the GNU General Public License as published by the Free Software
! Foundation, either version 3 of the License, or (at your option) any later
! version.
!
! PALM is distributed in the hope that it will be useful, but WITHOUT ANY
! WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
! A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License along with
! PALM. If not, see <http://www.gnu.org/licenses/>.
!
! Copyright 1997-2018 Leibniz Universitaet Hannover
!------------------------------------------------------------------------------!
!
! Current revisions:
! -----------------
! 
! cbegeman
! define sa_slope_offset and sa_slope_ref
! 
! Former revisions:
! -----------------
! $Id: init_slope.f90 2718 2018-01-02 08:49:38Z maronga $
! Corrected "Former revisions" section
! 
! 2696 2017-12-14 17:12:51Z kanani
! Change in file header (GPL part)
!
! 2101 2017-01-05 16:42:31Z suehring
!
! 2000 2016-08-20 18:09:15Z knoop
! Forced header and separation lines into 80 columns
! 
! 1682 2015-10-07 23:56:08Z knoop
! Code annotations made doxygen readable 
! 
! 1353 2014-04-08 15:21:23Z heinze
! REAL constants provided with KIND-attribute
!
! 1322 2014-03-20 16:38:49Z raasch
! REAL constants defined as wp_kind
!
! 1320 2014-03-20 08:40:49Z raasch
! ONLY-attribute added to USE-statements,
! kind-parameters added to all INTEGER and REAL declaration statements,
! kinds are defined in new module kinds,
! revision history before 2012 removed,
! comment fields (!:) to be used for variable explanations added to
! all variable declaration statements
!
! 1036 2012-10-22 13:43:42Z raasch
! code put under GPL (PALM 3.9)
!
! Revision 1.1  2000/04/27 07:06:24  raasch
! Initial revision
!
!
! Description:
! ------------
!> Initialization of the temperature field and other variables used in case
!> of a sloping surface.
!> @note when a sloping surface is used, only one constant temperature
!>       gradient is allowed!
!------------------------------------------------------------------------------!
 SUBROUTINE init_slope
 

    USE arrays_3d,                                                             &
        ONLY:  hyp, pt, pt_init, pt_slope_ref, zu, &
               sa, sa_init, sa_slope_ref
        
    USE constants,                                                             &
        ONLY:  pi
                    
    USE control_parameters,                                                    &
        ONLY:  alpha_surface, ambient_density_for_buoyancy,                    &
               initializing_actions, ocean,                                    &
               pt_surface, pt_vertical_gradient, pt_slope_offset,              &
               sa_surface, sa_vertical_gradient, sa_slope_offset,              &
               sin_alpha_surface, slope_offset 

    USE eqn_state_seawater_mod,                                                &
        ONLY:  eqn_state_seawater, eqn_state_seawater_func

    USE grid_variables,                                                        &
        ONLY:  dx
        
    USE indices,                                                               &
        ONLY:  ngp_2dh, nx, nxl, nxlg, nxr, nxrg, nyn, nyng, nys, nysg, nzb, nzt
        
    USE kinds

    USE pegrid


    IMPLICIT NONE

    INTEGER(iwp) ::  i        !<
    INTEGER(iwp) ::  j        !<
    INTEGER(iwp) ::  k        !<
    
    REAL(wp), DIMENSION(:), ALLOCATABLE ::  pt_init_local !<
    REAL(wp), DIMENSION(:), ALLOCATABLE ::  sa_init_local !<

    CALL location_message('Initialize slope',.TRUE.)

!-- Temperature and salinity difference between left and right boundary of the total domain,
!-- used for the cyclic boundary in x-direction
    IF ( slope_offset ) THEN
       pt_slope_offset = (nx+1) * dx * sin_alpha_surface * &
                         pt_vertical_gradient(1) / 100.0_wp

       IF ( ocean ) THEN
          sa_slope_offset = (nx+1) * dx * sin_alpha_surface * &
                            sa_vertical_gradient(1) / 100.0_wp
       ENDIF

    ENDIF
!
!-- Following action must only be executed for initial runs
    IF ( TRIM( initializing_actions ) /= 'read_restart_data' )  THEN
!
!--    Set initial temperature equal to the reference temperature field
       DO  j = nysg, nyng
          pt(:,j,:) = pt_slope_ref
          IF ( ocean ) sa(:,j,:) = sa_slope_ref
       ENDDO

!
!--    Recompute the mean initial temperature profile (mean along x-direction of
!--    the rotated coordinate system)
       ALLOCATE( pt_init_local(nzb:nzt+1) )
       IF ( ocean ) ALLOCATE( sa_init_local(nzb:nzt+1) )
       pt_init_local = 0.0_wp
       IF ( ocean ) sa_init_local = 0.0_wp
       DO  i = nxl, nxr
          DO  j =  nys, nyn
             DO  k = nzb, nzt+1
                pt_init_local(k) = pt_init_local(k) + pt(k,j,i)
                IF ( ocean ) sa_init_local(k) = sa_init_local(k) + sa(k,j,i)
             ENDDO
          ENDDO
       ENDDO

#if defined( __parallel )
       IF ( collective_wait )  CALL MPI_BARRIER( comm2d, ierr )
       CALL MPI_ALLREDUCE( pt_init_local, pt_init, nzt+2-nzb, MPI_REAL, &
                            MPI_SUM, comm2d, ierr )
       IF ( ocean ) CALL MPI_ALLREDUCE( sa_init_local, sa_init, nzt+2-nzb, MPI_REAL, &
                            MPI_SUM, comm2d, ierr )
#else
       pt_init = pt_init_local
       IF ( ocean ) sa_init = sa_init_local
#endif

       pt_init = pt_init / ngp_2dh(0)
       IF ( ocean ) sa_init = sa_init / ngp_2dh(0)
       DEALLOCATE( pt_init_local )
       IF ( ocean ) DEALLOCATE( sa_init_local )

    ENDIF

 END SUBROUTINE init_slope
