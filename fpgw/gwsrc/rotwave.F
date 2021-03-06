c$$$      module m_spacegrouprot
c$$$      integer(4),allocatable :: invgx(:), miat(:,:)
c$$$      real(8),allocatable    :: tiat(:,:,:),shtvg(:,:)
c$$$      contains !-------------------------------------------
c$$$      subroutine Spacegrouprot(symgg,ngrp,plat,natom,pos) !all input
c$$$      implicit none
c$$$      real(8)::symgg(*),plat(*),pos(*)
c$$$      integer::ngrp,natom,ificlass,iopen,ibas,ibasx,iclose
c$$$      integer,allocatable:: iclasst(:)
c$$$!!  Get data for space-group transformation. See header of mptaouof.
c$$$      ificlass   = iopen('CLASS',1,-1,0)
c$$$      allocate(iclasst(natom))
c$$$      write(6,*)'  --- Spacegrouprot: Readingin true CLASS info ---'
c$$$      do ibas = 1,natom
c$$$        read(ificlass,*) ibasx, iclasst(ibas)
c$$$        write(6, "(2i10)") ibasx, iclasst(ibas)
c$$$      enddo
c$$$      ificlass= iclose('CLASS')
c$$$      allocate( invgx(ngrp),miat(natom,ngrp),tiat(3,natom,ngrp),shtvg(3,ngrp))
c$$$      call mptauof(symgg,ngrp,plat,natom,pos,iclasst
c$$$     o     ,miat,tiat,invgx,shtvg )
c$$$      end subroutine
c$$$      end module 
c$$$!! ------------

      subroutine rotmto(qin,cphiin,nbloch,nband,
     i  norbt,ibas_tbl,l_tbl,k_tbl,offset_tbl,offset_rev_tbl,max_ibas_tbl,max_l_tbl,max_k_tbl,
     i  ginv,sym,shtvg,dlmm,lxxa,miat,tiat,igxt,nbas,
     o  cphiout)
!!== Rotation of a function of ProductBasis or MT part of wave function.
!! (then MTO itself is rotated. a little diffent from here).
!! See also mto part of lm7K/subs/rotwv.F
!!
!! qin  = qtti(:,iqi)
!! cphiin cphi(1:ldim2,1:nband,iqi,isp) eigenfunction @ qtti(:,iqi)
!! dlmm   dlmm(-l:l,-l:l,l,igg)
!! sym   symops(:,:,igg)
!! tiat   tiat(:,ibas,igg)
!! shtvg  shtvg(:,igg)
!! miat   miat(ibas,igg)
!!
!!  cphin (iqq) ---> cphiout (iq)
      implicit none
! input variables
      integer,intent(in):: nbloch,nband,norbt,nbas
      integer,intent(in):: ibas_tbl(norbt),l_tbl(norbt),k_tbl(norbt),offset_tbl(norbt)
      integer,intent(in):: miat(nbas),lxxa
      real(8),intent(in):: tiat(3,nbas)
      complex(8),intent(in):: cphiin(nbloch,1:nband)

      real(8),intent(in):: sym(3,3), qin(3),shtvg(3)
      real(8),intent(in):: dlmm(-lxxa:lxxa,-lxxa:lxxa,0:lxxa),ginv(3,3)
      integer,intent(in):: max_ibas_tbl,max_l_tbl,max_k_tbl,igxt
      integer,intent(in)::  offset_rev_tbl(max_ibas_tbl, 0:max_l_tbl, max_k_tbl)

! output variables
      complex(8),intent(out):: cphiout(nbloch,1:nband)

! local variables
      real(8) :: qrot(3)
      integer :: ibas,ibaso,l,k,ini1,iend1,ini2,iend2,iorb
      complex(8) :: phase

      complex(8),parameter:: img=(0d0,1d0)
      complex(8):: img2pi

      img2pi = 2d0*4d0*datan(1d0)*img ! MIZUHO-IR

      qrot = matmul(sym,qin)
      if(igxt==-1) qrot=-qrot !july2012takao
      ibaso=-999
      do iorb=1,norbt !orbital-blocks
c         write(6,*)'iorb=',iorb
        ibas = ibas_tbl(iorb)
        if(ibas/=ibaso) then
          phase = exp( -img2pi*sum(qrot*tiat(:,ibas))) 
        endif   
        ibaso=ibas
        l = l_tbl(iorb)
        k = k_tbl(iorb)
        ini1 = offset_tbl(iorb)+1
        iend1 = ini1+2*l
        ini2 = offset_rev_tbl(miat(ibas),l,k)+1
        iend2 = ini2+2*l
c        write(6,"(' === PBs index: iorb ibas l k ini1 ini2',10i4)")iorb,ibas,miat(ibas),l,k,ini1,ini2
        cphiout(ini2:iend2,:)= matmul(dlmm(-l:l,-l:l,l),cphiin(ini1:iend1,:))*phase
      enddo  
      end subroutine rotmto
      
!! ------------------------------------------------------
c      subroutine rotmto2(qin,cphiin,nbloch,nband,
      subroutine rotmto2(qin,nbloch,nband,
     i  norbt,ibas_tbl,l_tbl,k_tbl,offset_tbl,offset_rev_tbl,max_ibas_tbl,max_l_tbl,max_k_tbl,
     i  ginv,sym,shtvg,dlmm,lxxa,miat,tiat,igxt,nbas,
c     o  cphiout)
     o  zrotm)
!!== Rotation of a function of ProductBasis or MT part of wave function.
!! (then MTO itself is rotated. a little diffent from here).
!! See also mto part of lm7K/subs/rotwv.F
!!
!! qin  = qtti(:,iqi)
!! cphiin cphi(1:ldim2,1:nband,iqi,isp) eigenfunction @ qtti(:,iqi)
!! dlmm   dlmm(-l:l,-l:l,l,igg)
!! sym   symops(:,:,igg)
!! tiat   tiat(:,ibas,igg)
!! shtvg  shtvg(:,igg)
!! miat   miat(ibas,igg)
!!
!!  output: zrotm is the rotation matrix. c.f. cphiout in rotmto
      implicit none
      integer:: ibas,ibaso,nbloch,nband,norbt,iorb,nbas
      integer:: ibas_tbl(norbt),l_tbl(norbt),k_tbl(norbt),offset_tbl(norbt)
      integer:: l,k,ini1,iend1,ini2,iend2,miat(nbas),lxxa
      real(8):: tiat(3,nbas)
c      complex(8):: cphiin(nbloch,1:nband),cphiout(nbloch,1:nband),phaseq,phase,ddd
      complex(8):: phase,ddd
      real(8):: sym(3,3), qin(3),qrot(3),shtvg(3) !shtvg
      real(8):: dlmm(-lxxa:lxxa,-lxxa:lxxa,0:lxxa),ginv(3,3)
!      complex(8),parameter:: img=(0d0,1d0),img2pi=2d0*4d0*datan(1d0)*img ! MIZUHO-IR
      complex(8),parameter:: img=(0d0,1d0) ! MIZUHO-IR
      integer:: max_ibas_tbl,max_l_tbl,max_k_tbl,igxt
      integer::  offset_rev_tbl(max_ibas_tbl, 0:max_l_tbl, max_k_tbl),m1,m2
!!
c      integer:: nrotm,irotm1(nrotmmx),irotm2(nrotmx)
      integer:: nrotm,irotm1,irotm2
      complex(8):: zrotm(nbloch,nbloch)

      complex(8):: img2pi ! MIZUHO-IR
      img2pi = 2d0*4d0*datan(1d0)*img ! MIZUHO-IR

      qrot = matmul(sym,qin)
      if(igxt==-1) qrot=-qrot !july2012takao
      ibaso=-999
      do iorb=1,norbt !orbital-blocks
        ibas = ibas_tbl(iorb)
        if(ibas/=ibaso) then
          phase = exp( -img2pi*sum(qrot*tiat(:,ibas))) 
        endif   
        ibaso=ibas
        l = l_tbl(iorb)
        k = k_tbl(iorb)
        ini1 = offset_tbl(iorb)+1
        iend1 = ini1+2*l
        ini2 = offset_rev_tbl(miat(ibas),l,k)+1
        iend2 = ini2+2*l
c        write(6,"(' === PBs index: iorb ibas l k ini1 ini2',10i4)")iorb,ibas,miat(ibas),l,k,ini1,ini2
!! this is the case ofr rotmto
c        cphiout(ini2:iend2,:)= matmul(dlmm(-l:l,-l:l,l),cphiin(ini1:iend1,:))*phase*phaseq

!! We can get rotated rcxq as
!!      Rotated(rcxq)=  dconjg(chpiin(xx)) *  dconjg(zrotm)*rcxq(xx,irotm2) * zrotm(irotm2,irotm1)  * chpiin(irotm1)
        do m1=-l,l
        do m2=-l,l
          irotm1= ini1+m1+l
          irotm2= ini2+m2+l
          zrotm(irotm2,irotm1) = dlmm(m2,m1,l)*phase
        enddo
        enddo
      enddo
c      nrotm=ix
      end subroutine rotmto2

      
!! --------------------------------
      subroutine rotipw2(qin,qtarget,ngp,nband,
     &  platt,qlat,sym,ngvecp,ngvecprev,shtvg,igxt,imx,
c     o  geigenout)
     o  zrotm)
!! == Rotation of Plane wave part. by sym==
!!
!! Mapped from qtt(:,iqq) to qtt(:,iq)
!!   qtt(:,iq)= matmul(sym(igg),qtt(:,iqq))+some G vector
!!  geigenin (iqq) ---> geigenout (iq)
!!
!! output: zrotm, c.f.   geigenout(ig2,:) in rotipw
      
      implicit none
      real(8):: sym(3,3),qlat(3,3),platt(3,3)
     &  ,shtvg(3)
      integer:: ngp,imx,nband,
     &          ngvecp(3,ngp), !,iqq),
     &          ngvecprev(-imx:imx,-imx:imx,-imx:imx) !,iq)
      real(8):: qin(3),qpg(3),qpgr(3),qtarget(3)
      integer:: ig,ig2,nnn(3),igxt
c      complex(8):: geigenin(ngp,nband), geigenout(ngp,nband)
!      complex(8),parameter:: img=(0d0,1d0),img2pi=2d0*4d0*datan(1d0)*img ! MIZUHO-IR
      complex(8),parameter:: img=(0d0,1d0) ! MIZUHO-IR
      complex(8):: zrotm(ngp,ngp)

      complex(8):: img2pi ! MIZUHO-IR
      img2pi = 2d0*4d0*datan(1d0)*img ! MIZUHO-IR

!!     qout = matmul(sym,qin)+some Gvector !qout \equiv qtt(:,iq) , qin=qtt(:,iqq)
      do ig = 1,ngp !ngp(iqq)
        qpg = qin + matmul( qlat(:,:),ngvecp(:,ig)) !iqq !q+G     qin=qtt(:,iqq)
        qpgr = matmul(sym,qpg)             !rotated q+G
        if(igxt==-1) qpgr=-qpgr !july2012
        call conv2int( matmul(platt,qpgr-qtarget),nnn,3 )
c        if(maxval(abs(nnn))>imx) stop 'rotipw:maxval(abs(nnn))>imx'
        ig2 = ngvecprev(nnn(1),nnn(2),nnn(3))  !,iq)
c        geigenout(ig2,:)= geigenin(ig,:) * exp( -img2pi*sum(qpgr*shtvg) )
        zrotm(ig2,ig)= exp( -img2pi*sum(qpgr*shtvg) )
      enddo
      end subroutine rotipw2


!> Rotation of Plane wave part. by sym
!! Mapped from qtt(:,iqq) to qtt(:,iq)
!!   qtt(:,iq)= matmul(sym(igg),qtt(:,iqq))+some G vector
!!  geigenin (iqq) ---> geigenout (iq)
      subroutine rotipw(qin,qtarget,geigenin,ngp,nband,
     &  platt,qlat,sym,ngvecp,ngvecprev,shtvg,igxt,imx,
     o  geigenout)
      implicit none

      real(8), intent(in) :: sym(3,3),qlat(3,3),platt(3,3),shtvg(3)
      integer, intent(in) :: ngp,imx,igxt,nband,
     &   ngvecp(3,ngp),ngvecprev(-imx:imx,-imx:imx,-imx:imx)
      real(8), intent(in) :: qin(3),qtarget(3)
      complex(8), intent(in) :: geigenin(ngp,nband)
      complex(8), intent(out) :: geigenout(ngp,nband)

      real(8):: qpg(3),qpgr(3)
      integer:: ig,ig2,nnn(3)
!      complex(8),parameter:: img=(0d0,1d0),img2pi=2d0*4d0*datan(1d0)*img ! MIZUHO-IR
      complex(8),parameter:: img=(0d0,1d0) ! MIZUHO-IR

      complex(8):: img2pi ! MIZUHO-IR
      img2pi = 2d0*4d0*datan(1d0)*img ! MIZUHO-IR

!!     qout = matmul(sym,qin)+some Gvector !qout \equiv qtt(:,iq) , qin=qtt(:,iqq)
      do ig = 1,ngp !ngp(iqq)
        qpg = qin + matmul( qlat(:,:),ngvecp(:,ig)) !iqq !q+G     qin=qtt(:,iqq)
        qpgr = matmul(sym,qpg)             !rotated q+G
        if(igxt==-1) qpgr=-qpgr !july2012
        call conv2int( matmul(platt,qpgr-qtarget),nnn,3 )
c        if(maxval(abs(nnn))>imx) stop 'rotipw:maxval(abs(nnn))>imx'
        ig2 = ngvecprev(nnn(1),nnn(2),nnn(3))  !,iq)
        geigenout(ig2,:)= geigenin(ig,:) * exp( -img2pi*sum(qpgr*shtvg) )
      enddo
      end subroutine rotipw


!!------------------------------------------------------
      subroutine rotwvigg(igg,q,qtarget,ndimh,napw_in,nband,evec,evecout,ierr)
      use m_hamindex,only: symops,invgx,miat,tiat,shtvg,qlat,plat,dlmm,ngrp,norbmto,
     &  ibastab,ltab,ktab,offl,offlrev,getikt,igv2,igv2rev,napwk
      implicit none
!! == Wave function rotator evec to evectout by symops(:,:,igg). ===
!! INPUT:
!!  need to supply qtarget=sym*q for check (you can modify this code to skip this.
!! OUTPUT evecout, ierr 
!! NOTE:
!! rotation of coefficients on PMT basis. 
!!  phi(r) = \sum_i evec(i,iband) |F_i> ==> Roteta[phi](r)=\sum_i evecout(i,iband) |F_i>  by sym(:,:,ig).
!!  Rotate[phi](r)= phi[sym^-1(r)], where   sym(r)=r'= symops*r + shftvg.
!!  miat tiat are atom-mapping table. mptauo.F
!! c.f. rotsig in lm7K/fp/rotwv.F also.
      integer   :: ig,ndimh,napw_in,nband,ibaso,iorb,nnn(3),igx,init1,init2,iend1,iend2,nlmto,ierr,igg,ikt2,ikt,l,ibas,ig2,k
      real(8)   :: q(3),gout(3),delta(3),ddd(3),qpg(3),platt(3,3),qtarget(3),qx(3),det,qpgr(3),ddd2(3) !,plat(3,3),qlat(3,3)
      complex(8):: evec(ndimh,nband),evecout(ndimh,nband),phase,img=(0d0,1d0),img2pi
      real(8)::tolq=1d-8
      img2pi=2*4d0*datan(1d0)*img
      platt = transpose(plat) !this is inverse of qlat
      ierr=1
!! check q is really rotated to qtarget by symops(:,:,igg)
      call rangedq( matmul(platt,(qtarget-matmul(symops(:,:,igg),q)) ), qx)
      if(sum(abs(qx))>tolq) then
        write(6,"(a,3f7.3,2x,3f7.3)")'  rotwvigg: qtarget is not a star of q',q,qtarget
        call rx( 'rotwvigg: qtarget is not symops(:,:,ig)*q')
      endif  
      evecout=0d0
      nlmto = ndimh-napw_in
!! mto part
c          write(6,"(3i3,2x,2i5,3x,a)")
c     &    ib,l,k, offl(iorb,ib)+1,offl(iorb,ib)+2*l+1,trim(spid)
c      write(6,*)'rotwvigg :nlmto=',nlmto,norbmto
c      write(6,*)' ibastab=',ibastab
      if(nlmto/=0) then
        ibaso=-999
        do iorb=1,norbmto !orbital-blocks are specified by ibas, l, and k.
          !Index of Hamiltonian is devided into these blocks.
          ibas = ibastab(iorb)
          if(ibas/=ibaso) phase = exp( -img2pi*sum(qtarget*tiat(:,ibas,igg)) )
          ibaso=ibas
          l   = ltab(iorb)
          k   = ktab(iorb)
          init1 = offl(iorb)+1
          iend1 = offl(iorb)+2*l+1
          init2 = offlrev(miat(ibas,igg),l,k)+1
          iend2 = offlrev(miat(ibas,igg),l,k)+2*l+1
          evecout(init2:iend2,:)= matmul(dlmm(-l:l,-l:l,l,igg),evec(init1:iend1,:))*phase
        enddo
      endif
!! apw part
      if(napw_in/=0) then
        ikt  = getikt(q)    !index for q
        ikt2 = getikt(qtarget) !index for qtarget !you
        if(napw_in /= napwk(ikt) ) then
          call rx_('rotwv: napw_in /= napw(ikt)')
        endif
        do ig = 1,napw_in
          qpg = q + matmul( qlat(:,:),igv2(:,ig,ikt))      !q+G
          qpgr = matmul(symops(:,:,igg),qpg)              !rotated q+G
          call conv2int( matmul(platt,qpgr-qtarget),nnn,3 )
          ig2 = igv2rev(nnn(1),nnn(2),nnn(3),ikt2)
          if(ig2>=999999) then !See igv2rev=999999 in L354 in lm7K/subs/suham.F
             write(6,*)'rotwvigg: q  =',q
             write(6,*)'rorwvigg: qr =', matmul(symops(:,:,igg),q) 
             write(6,*)'rorwvigg: igv2   ikt ig2=',igv2(:,ig,ikt),ikt,ig2
             write(6,*)'rorwvigg: igv2rev   ikt2=',nnn(1),nnn(2),nnn(3),ikt2
             call rx('rotwvigg can not find index of mapped G vector ig2')
          endif
          evecout(nlmto+ig2,:)= evec(nlmto+ig,:) * exp( -img2pi*sum(qpgr*shtvg(:,igg)) )
        enddo
      endif
      ierr=0
      end
      
