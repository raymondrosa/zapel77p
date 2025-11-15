c     program ZAPEL77, October 2005
c     program ZAPEL77P, Updated on SEP 24, 2010
c
c beams on elastic foundation with variable soil modulus
c
      dimension ff(2,6),g(99999),c(6),m(2),y(11),de(4),sl(4),rm(4),vv(4)
     1,disp(10),slop(10),shea(10),rmom(10),nis(1000),njs(1000),nh(8),pas
     2(1000),pbs(1000),rls(1000),rlos(1000),rkos(1000),xs(1000),exps(100
     30),angs(1000),sm(21,1000),fms(6,1000),ris(1000),nrem(2),ltog(6),nd
     4es(80),nca(3),s(21),rhs(3003),n(7),aa(7),fm(6),ki(3,8),kdir(4),LRE
     5L(2),LIBRE(2,1000),ROTA(2,1000)
      DIMENSION AUX1(6,1000),AUX2(6,1000),GLOX(1000),xtot(11),CORTE(11),
     1OUTM(11),OUTD(11)
c
C LIMITATIONS: 1000 ELEM.,nodes<1001,NODES*3<3003,(1/2 BANDWIDTH*3*NODES)<99999,
c              (1/2 BANDWIDTH<303) 
c

      character fname*15,SALIR*30,EXNAM*30
c define input/output channels
      write (*,1001)
 1001 format (' data file name (*:*******.***)= ')
      read (*,1002) fname
 1002 format (a)
C
      WRITE (*,1211) 
 1211 FORMAT (' output file name (*:*******.***)= ')
      READ (*,1002) SALIR

C
      WRITE (*,335)
  335 FORMAT (' WRITE 1 FOR STORAGE IN A FILE TO BE POST-PROCESSED BY EX
     1CEL'/' OR WRITE ZERO IF FUTURE GRAPHICAL OUTPUT IS NOT NEEDED = ')
      READ (*,*) KSTOR
      IF (KSTOR) 338,338,336
  336 WRITE (*,337)
  337 FORMAT (' WRITE NAME OF FILE TO BE IMPORTED FROM EXCEL = ')
      READ (*,349) EXNAM
  349 FORMAT (A)
  338 CONTINUE
C
      open (5,file=fname)
C
      open (6,file=SALIR)

      write (6,1417)
 1417 format (' ',72('-'))
      WRITE (6,1415) FNAME,SALIR
 1415 FORMAT (' YOU ARE USING COMPUTER PROGRAM ZAPEL77, DEVELOPED BY DR.
     1 BERNARDO DESCHAPELLES'//' ',8X,'INPUT DATA FILE NAME IS = ',
     2A15/ ' ',8X,'OUTPUT DATA FILE NAME IS =',A30)
      IF (KSTOR) 9979,9979,9980
 9980 WRITE (6,9981) EXNAM
 9981 FORMAT (' ',8X,'STORAGE FILE FOR POST-PROCESSING WITH EXCEL = ',
     1A30)
 9979 continue

C
c input no. of cases to be studied
      read (5,501)  kasos
  501 format(i3)
      do 500 ml=1,kasos
c     write (6,502) ml
c 502 format('  case no.:',i3,3x,'analysis of beam on elastic foundation
c    1'///)
      write (6,1419)
 1419 format (' ',72('-')/' ',72('-'))
c ndes=array to store alphameric description of the job
      read (5,19) (ndes(k),k=1,40)
   19 format (40a2)
      write (6,69) (ndes(k),k=1,40)
   69 format(' ', 40a2)
c nm=number of elements formed by columns or beams with or without
c     elastic foundation along the length
c nn=number of nodes with 3 degrees of freedom each
c na=number of nodes with total or elastic restraint to displacement
c nspd=number of nodes where non zero displacement is prescribed
c jbw=upper band width=3 plus 3 times maximum difference between node
c     numbers of any element
c nca(1)= # of nodes with applied concentrated force parallel to axis x
c nca(2)= # of nodes with applied concentrated force parallel to axis y
c nca(3)= # of nodes with applied concentrated  moment
c ela=modulus of elasticity
ccc   all values in kips and/or feet units
      read (5,20) nm,nn,na,nspd,jbw,(nca(l),l=1,3),ela
   20 format (8i3,e11.4)
c initialization of right hand side in sytem of equations,array rhs
      neq=3*nn
      do 37 l=1,neq
   37 rhs(l)=0.
c           heading for echo print of member properties
      write (6,74) ela
   74 format (/' modulus of elasticity of beam material=',f9.0,' k/ft2'
     1//' memb nodes inertia  span  distrib. load soil modulus,k/ft2,',
     2'width incl.  angle'/' ',5x,'i   j  ft.4     ft    at i   at j',
     3'  const.  exponential  variation  rad'/)

C READING ELEMENT PARAMETERS
c                 do loop to cover all elements
      do 29 ne=1,nm
c nom=element number - ni,nj=node numbers, ni smaller than nj.
c   local x axis is defined by direction going from node ni to node nj.
c ri,area,rl = moment of inertia, area and span of element.
c soil modulus varies in accordance with the law x*(rlo+z)**exp, where
c x,rlo,and exp are constants, and z represents coordinate of position.
c pa,pb=values of transverse linearly distributed load,at nodes ni,nj.
c ang=angle,degrees,that local axes are rotated with respect to global.
c ri= moment of inertia at first node
c ci= moment of inertia at center of span
c bi= moment of inertia at second node
C LREL(1),LREL(2)=HINGING PARAMETER AT 1st,2nd NODE
       read (5,21) nom,ni,nj,ri,area,rl,rko,x,exp,pa,pb,ang,bi,ci,
     1LREL(1),LREL(2)
   21 format (3i3,f8.5,2F6.2,F6.0,4F6.3,f7.2,2f6.2,2I1)
      ang=ang*0.0174533
      write (6,76) nom,ni,nj,ri,rl,pa,pb,rko,x,exp,ang,LREL(1),LREL(2)
   76 format (' ',i2,2i4,f8.5,f6.2,2f7.3,f8.2,4x,f6.1,8x,f5.1,1x,f7.3,
     11X,2I1)
      write (6,77)
   77 format (' ',47x,'+ (',6x,')*(x)**(',5x,')')
      rlo=0.
      if (bi) 71,71,72
   71 pi=0.
      ee=0.
      go to 73
   72 pi=bi-ri
      ratio=abs((ci-ri)/(bi-ri))
      ee=log(ratio)/log(0.5)
   73 continue
c -contribution of beam and constant soil modulus to element stiffness
      call sbmso (ri,area,rl,ela,rko,s,pi,ee)
      if (x) 12,11,12
c -contribution of exponential part of soil modulus to element stiffness
   12 call stsov (rl,rlo,exp,x,s)
c -equivalent nodal concentrations due to distributed load in the span
   11 call eqnod (rl,pa,pb,ang,ni,nj,fm,rhs,LREL,S,NOM,ROTA,AUX1,AUX2)
      if (ang) 16,15,16
c -transformation of stiffness matrix to global coordinates if needed
   16 call stran (s,ang)
   15 CONTINUE

      IF (ANG) 1115,1116,1115 
 1115 GLOX(NJ) = GLOX(NI) + ABS(RL*SIN(ANG))
      GO TO 1117
 1116 GLOX(NJ) = GLOX(NI) + RL*COS(ANG)
 1117 CONTINUE

      nis(nom)=ni
      njs(nom)=nj
      pas(nom)=pa
      pbs(nom)=pb
      rls(nom)=rl
      rkos(nom)=rko
      rlos(nom)=rlo
      xs(nom)=x
      exps(nom)=exp
      angs(nom)=ang
      ris(nom)=ri
      do 1914 l=1,6
 1914 fms(l,nom)=fm(l)
      do 1915 l=1,21
 1915 sm(l,nom)=s(l)
      DO 1918 L=1,2
 1918 LIBRE(L,NOM)=LREL(L)
   29 continue

c     WRITE (6,2928) NN
c2928 FORMAT ('   ABSCISSAE OF THE ',I4,' NODES')
c     DO 2929 L=1,NN
c2929 WRITE (6,2927) L,GLOX(L)
c2927 FORMAT (' ',I20,6X,F10.2)

c initialization of single subscripted array   g  in which the global
c                   stiffness matrix is stored
      nterm=neq*jbw
      do 1939 l=1,nterm
 1939 g(l)=0.
c        write in array  g  contribution of all elements
      do 1940 ne=1,nm
      ltog(1)=3*nis(ne)-2
      ltog(2)=ltog(1)+1
      ltog(3)=ltog(1)+2
      ltog(4)=3*njs(ne)-2
      ltog(5)=ltog(4)+1
      ltog(6)=ltog(4)+2
      do 1941 i=1,6
c       processing of 6 rows of element stiffness matrix
      igl=ltog(i)
      do 1941 j=i,6
c     processing of 6 columns in upper triangle of stiffness matrix
      jgl=ltog(j)
      jcomp=jgl-igl+1
      is=(igl-1)*jbw+jcomp
c           position  (is) in global stiffness matrix
      ij=(j-1)*j/2+i
 1941 g(is)=g(is)+sm(ij,ne)
 1940 continue
      WRITE (6,1815) NM
 1815 FORMAT (/' STIFFNESS CONTRIBUTION OF ALL ',I3,' ELEM. ALREADY',
     1' PROCESSED')
c                  input of boundary conditions
c       to read information related to boundary conditions
c- na=no. of nodes with total or elastic restraint to displacement
c- nspd=no. of nodes where non zero displacement is prescribed
   78 nspr=0
      if (na) 30,30,57
c--information concerning nodes with any type of displacement restraint
c  for any node n, three integers ki are given to cover conditions along
c  the 3 global axes. integer +1 denotes full restraint, zero indicates
c  no restriction at all and (-1) implies the esistence of a spring
c if ki is entered as(-1) the number of springs,nspr, is increased
   57 WRITE (6,1813) NA
 1813 FORMAT (' ',4X,/' INPUT DATA RELATED TO THE ',I2,' SUPPORTS')
      knt=0
  200 read (5,26) nf,(nh(k),(ki(l,k),l=1,3),k=1,nf)
   26 format (33i2)
      WRITE (6,1814) nf,(nh(k),(ki(l,k),l=1,3),k=1,nf)
 1814 FORMAT (' ',33I2)
      knt=knt+nf
      do 27 k=1,nf
      do 27 l=1,3
      if (ki(l,k)) 280,27,290
  280 nspr=nspr+1
      go to 27
  290 spdis=0.
      in=nh(k)
      call symo1 (jbw,g,rhs,nn,in,l,spdis)
   27 continue
      if (knt-na) 200,30,30
   30 nrem(1)=nspr
      nrem(2)=nspd
c--two loops (l=1,2) to cover remaining input
c- l=1, information of spring constants, to be given if in input above
c  some negative integers have been written to indicate the existence
c  of elastic restraints
c- l=2, information of prescribed non zero displacements, if any
      do 100 l=1,2
      knt=0
      if (nrem(l)) 100,100,101
c- for each node n an integer kdir is given to define the direction
c  along which the restraint operates or the displacement is specified
c- integers 1,2 and 3 correspond to directions x,y and z respectively
c- variable aa defines value of spring constant or specified displ.
  101 read (5,370) nf,(nh(k),kdir(k),aa(k),k=1,nf)
  370 format (i2,4(2i2,e12.5))
      knt=knt+nf
      do 127 k=1,nf
      go to (105,106), l
  105 nl=3*(nh(k)-1)+kdir(k)
c                      processing the spring
      is=(nl-1)*jbw+1
      g(is)=g(is)+aa(k)
      go to 127
  106 spdis=aa(k)
c              processing of specified displacements
      in=nh(k)
      ld=kdir(k)
      call symo1 (jbw,g,rhs,nn,in,ld,spdis)
  127 continue
      if (knt-nrem(l)) 101,100,100
  100 continue
c- input and processing of concentrated loads applied at nodal points
      do 49 l=1,3
      if (nca(l)) 49,49,48
   48 knt=0
   98 read (5,46) nf,(nh(k),aa(k),k=1,nf)
   46 format (i2,7(i2,f7.2))
      knt=knt+nf
      do 47 k=1,nf
      is=3*(nh(k)-1)+l
   47 rhs(is)=rhs(is)+aa(k)
      if (knt-nca(l)) 98,49,49
   49 continue
      do 1953 nr=1,neq
      i1=(nr-1)*jbw+1
      if (g(i1)) 1954,1954,1953
 1954 write (6,1955)nr
 1955 format(' INSTABILITY ALONG COORDINATE NO.',i4)
      write (6,1022)
      stop
 1953 continue
      WRITE (6,1812) NEQ
 1812 FORMAT (' ',4X,/' SOLUTION OF THE ',I3,' EQUATIONS STARTING NOW'/)
c                   solve system of equations
      call symso (g,rhs,neq,jbw)
c                 output of nodal displacements
      call doutp (rhs,nn)
      do 2000 l=1,neq
 2000 g(l)=0.

      IF (KSTOR) 817,817,1111
 1111 OPEN (2,FILE=EXNAM,STATUS='NEW',FORM='FORMATTED',ERR=9999,
     1RECL=64)
      WRITE (2,3419)
 3419 FORMAT(' .ELEM .ABSCISSA .REACTION .ABSCISSA ....SHEAR .ABSCISSA .
     1..MOMENT .ABSCISSA ....DISPL')

c When importing output file from EXEL text import wizard, step 1 of 3,
c option 'FIXED WIDTH' should be selected. In step 2 use option 'SPACE'.

  817 CONTINUE

      do 91 nom=1,nm
c                 do loop to cover all elements
      do 1945 l=1,21
 1945 s(l)=sm(l,nom)
      m(1)=nis(nom)
      m(2)=njs(nom)
      pa=pas(nom)
      pb=pbs(nom)
      rl=rls(nom)
      rko=rkos(nom)
      rlo=rlos(nom)
      x=xs(nom)
      exp=exps(nom)
      ang=angs(nom)
      ri=ris(nom)
      do 1946 l=1,6
 1946 fm(l)=fms(l,nom)
      call efpre (rhs,s,rko,rlo,x,exp,rl,m,ang,fm,ff,y,NOM,LIBRE,ROTA,
     1AUX1,AUX2)
      do 44 k=1,10
      if (rko) 22,121,22
  121 if (x) 22,23,22
   23 do 24 kk=1,4
      de(kk)=0.
      sl(kk)=0.
      rm(kk)=0.
   24 vv(kk)=0.
      go to 25
   22 call cdevv (rko,rlo,x,exp,rl,k,co,c,de,vv)
      call coslm (rko,rlo,x,exp,rl,k,co,c,sl,rm)
   25 call resbm (ff,rl,ri,ela,k,de,vv,sl,rm,disp,slop,shea,rmom,pa,pb)
   44 continue
      call boutp (nom,m,rl,y,ff,shea,rmom,disp,GLOX,CORTE,OUTM,XTOT
     1,OUTD)

      IF (KSTOR) 91,91,9990
 9990 WRITE (2,9991) NOM
 9991 FORMAT (' ',I5)
      DO 9992 KK=1,11
 9992 WRITE (2,9993) XTOT(KK),Y(KK),XTOT(KK),CORTE(KK),XTOT(KK),OUTM(KK)
     1,XTOT(KK),OUTD(KK)
 9993 FORMAT (' ',5X,8F10.4)

   91 continue
  500 continue
      WRITE (6,1022)
 1022 FORMAT (' ')
      STOP
 9999 WRITE (6,9998) EXNAM
 9998 FORMAT ('      FILE  ',A30,'  CAN NOT BE OPENED THIS TIME')
      WRITE (6,1022)
      stop
      end
c**********************************************************************
c**********************************************************************
      subroutine sbmso (ri,area,rl,e,rko,s,pi,p)
c  purpose-generate stiffness matrix of a beam on elastic foundation
c  considering soil modulus with constant value throughout the span
c \777considering soil modulus with constant value throughout the span
c e=modulus of elasticity. rl=beam span. area=equivalent cross section
c area. moment of inertia=ri+pi*(coord)**p, where coord represents
c normalized coordinate of position along the span
c rko=constant value of soil modulus, force per unit area
c s=stiffness matrix, upper triangle, expressed as a single
c subscripted array taking the terms columnwise
      dimension s(21),t(21)
      p1=p+1
      p2=p+2
      p3=p+3
      do 4 k=1,21
      t(k)=0.
      s(k)=0.
    4 continue
c contribution of the beam to element stiffness, array s
      s( 1)= area
      s( 7)=-s(1)
      s(10)= s(1)
      s( 3)= 12.*ri/rl**2+36.*pi*(1./p1-4./p2+4./p3)/rl**2
      s( 5)= 6.*ri/rl+12.*pi*(2./p1-7./p2+6./p3)/rl
      s( 6)=4.*ri+4.*pi*(4./p1-12./p2+9./p3)
      s(12)=-s(3)
      s(13)=-s(5)
      s(15)=s(3)
      s(17)= 6.*ri/rl+12.*pi*(1./p1-5./p2+6./p3)/rl
      s(18)=2.*ri+4.*pi*(2./p1-9./p2+9./p3)
      s(20)=-s(17)
      s(21)= 4.*ri+4.*pi*(1./p1-6./p2+9./p3)
      do 1 k=1,21
      s(k)=s(k)*e/rl
    1 continue
c contribution of the soil to element stiffness, array t
      t(3)=13./35.
      t(5)=11.*rl/210.
      t(6)=rl**2/105.
      t(12)=9./70.
      t(13)=13.*rl/420.
      t(15)=t(3)
      t(17)=-t(13)
      t(18)=-rl**2/140.
      t(20)=-t(5)
      t(21)=t(6)
      do 2 k=1,21
      t(k)=t(k)*rko*rl
    2 continue
      do 3 k=1,21
      s(k)=s(k)+t(k)
    3 continue
      return
      end
c**********************************************************************
c*********************************************************************
      subroutine stsov (rl,rlo,exp,x,s)
c purpose- add to the stiffness matrix of a beam on elastic foundation
c part related to exponential variation of soil modulus along the span
c three degrees of freedom at each node
c meaning of arguments
c  rl=beam span
c soil varies in accordance with the law x*(rlo+z)**exp, where
c x,rlo, and exp are constants and represents coordinate of position
c v=stiffness matrix contribution, upper triangle only, stored as single
c subscripted array, taking the terms columnwise
c s=total stiffness matrix, stored also as single subscripted array
      dimension c(6), v(21), s(21)
      do 5 k=1,21
      v(k)=0.
    5 continue
c    calculation of constants related to the terms of array v
      e1=exp+1.
      p=(rlo+rl)**e1
      q=rlo**e1
      co=(p-q)/(rl*e1)
      c(1)=(p-rlo*co)/(rl*(e1+1.))
      do 3 k=2,6
      c(k)=(p-rlo*float(k)*c(k-1))/(rl*(e1+float(k)))
    3 continue
      v(3)=co-6.*c(2)+4.*c(3)+9.*c(4)-12.*c(5)+4.*c(6)
      v(5)=rl*(c(1)-2.*c(2)-2.*c(3)+8.*c(4)-7.*c(5)+2.*c(6))
      v(6)=rl**2*(c(2)-4.*c(3)+6.*c(4)-4.*c(5)+c(6))
      v(12)=3.*c(2)-2.*c(3)-9.*c(4)+12.*c(5)-4.*c(6)
      v(17)=rl*(-c(2)+c(3)+3.*c(4)-5.*c(5)+2.*c(6))
      v(18)=rl**2*(-c(3)+3.*c(4)-3.*c(5)+c(6))
      v(15)=9.*c(4)-12.*c(5)+4.*c(6)
      v(20)=rl*(-3.*c(4)+5.*c(5)-2.*c(6))
      v(21)=rl**2*(c(4)-2.*c(5)+c(6))
      v(13)=rl*(3.*c(3)-8.*c(4)+7.*c(5)-2.*c(6))
      do 4 k=1,21
      s(k)=x*rl*v(k)+s(k)
    4 continue
      return
      end
c**********************************************************************
c*********************************************************************
      subroutine stran (s,ang)
c performs matrix transformation caused by rotation of coordinates
c -argument ang=angle that local axis is rotated with respect to global
c  axis, in radians, positive counterclockwise
c -argument s= symmetric matrix to be transformed, 6 rows by 6 columns
c  stored in compact format, as per single subscripted array formed taki
c  columnwise the terms of the upper triangle- returns transformed
      dimension a(36), s(21), ats(36)
c construct transformation matrix, as single subscripted array, a,
c taking columnwise the 36 terms
      do 32 j=1,36
      a(j)=0.
   32 continue
      do 33 j=1,2
      do 33 k=1,8,7
      l=k+21*(j-1)
      a(l)=cos(ang)
   33 continue
      do 34 j=2,7,5
      isign=(-1)**(j+1)
      do 34 k=1,2
      l=j+(k-1)*21
      a(l)=isign*sin(ang)
   34 continue
      do 35 j=15,36,21
      a(j)=1.
   35 continue
c -perform the multiplication of a transpose times s - result is array a
      do 1 i=1,6
      do 1 j=1,6
c kats=single subscript of term (i,j) in array ats
      kats=(j-1)*6+i
      ats(kats)=0.
      do 1 k=1,6
      if (k-j) 2,2,3
c  is=single subscript of term (k,j) in array s, if k less than or equal
c  to  j, that is term located in the upper triangle
    2 is=(j-1)*j/2+k
      go to 5
c- is=single subscript of term (k,j) in array s, if k larger than j
    3 is=(k-1)*k/2+j
c- kat=single subcript of term (i,k) in matrix at,or (k,i) in matrix a
    5 kat=(i-1)*6+k
      ats(kats)=ats(kats)+s(is)*a(kat)
    1 continue
c--perform multiplication of matrix ats by matrix a - result is matrix s
      do 6 i=1,6
      do 6 j=i,6
c -is=single subscript of term (i,j) in array s
      is=(j-1)*j/2+i
      s(is)=0.
      do 6 k=1,6
c -kats=single subscript of term (i,k) in array ats
      kats=(k-1)*6+i
c -ka=single subscript of term (k,j) in array a
      ka=(j-1)*6+k
      s(is)=s(is)+ats(kats)*a(ka)
    6 continue
      return
      end
c**********************************************************************
c*********************************************************************
      subroutine eqnod (rl,pa,pb,ang,ni,nj,fm,rhs,LREL,S,NOM,ROTA,
     1AUX1,AUX2)
      dimension fm(6),a(36),gfm(6),rhs(3003),LREL(2),S(21),AUX(6)
     1,ROTA(2,1000),AUX1(6,1000),AUX2(6,1000)
c  generates vector fm, fixed end forces and moments caused by distribu-
c  ted load varying linearly from value pa at node ni to value pb at
c  node nj of beam with length rl - these equivalent concentrations are
c  transformed if local axes are rotated angle ang with respect to
c  global axes are final values, array gfm, are incorporated to the
c  right hand side of the system of equations, vector rhs
      fm(1)=0.
      fm(2)=pa*rl/2.+3.*(pb-pa)*rl/20.
      fm(3)=pa*rl**2/12.+(pb-pa)*rl**2/30.
      fm(4)=0.
      fm(5)=pa*rl/2.+7.*(pb-pa)*rl/20.
      fm(6)=-pa*rl**2/12.-(pb-pa)*rl**2/20.
C     WRITE (6,1901) NOM,(FM(L),L=1,6)
C1901 FORMAT (' EQUIV NODAL FORCES AT ELEM ',I3,' (FIXED ENDS)'/
C    1' ',6E12.4)
CCCCCCCCCCCCCCCCCCCCCC
C
      DO 59 L=1,2
      IF(LREL(L))59,59,60
C STIFFNESS RELEASE
   60 GO TO(61,62),L
   61 N=3
      GO TO 63
   62 N=6
C-SAVE ROW(N)OF STIFFENESS MATRIX IN ARRAY(AUX)
   63 DO 64 JJ=1,6
      NJJ=(JJ-1)*JJ/2+N
      IF(JJ-N)65,66,66
   65 NJJ=(N-1)*N/2+JJ
   66 AUX(JJ)=S(NJJ)
   64 CONTINUE
C 888888888888888
      IF (N-3) 620,620,630
  620 DO 621 JJ=1,6
  621 AUX1(JJ,NOM)=AUX(JJ)/AUX(N)
      WRITE (6,651) NOM
  651 FORMAT (' ',8X,' ELEM',I3,' HAS HINGED CONNECTION AT ITS 1st END')
C     WRITE (6,651) NOM,(AUX1(JJ,NOM),JJ=1,6)
C 651 FORMAT (' ',4X,'THIRD ROW OF STIFFNESS MATRIX OF ELEM',I3/
C    1' ',6E12.4)
      GO TO 640
  630 DO 631 JJ=1,6
  631 AUX2(JJ,NOM)=AUX(JJ)/AUX(N)
      WRITE (6,652) NOM
  652 FORMAT (' ',8X,' ELEM',I3,' HAS HINGED CONNECTION AT ITS 2nd END')
C     WRITE (6,652) NOM,(AUX2(JJ,NOM),JJ=1,6)
C 652 FORMAT (' ',4X,'SIXTH ROW OF STIFFNESS MATRIX OF ELEM',I3/
C    1' ',6E12.4)
  640 CONTINUE
C 888888888888888
      RHN=fm(n)
C-PERFORM ELIMINATION IN ROWS OTHER THAN(N)
      DO 771 M=1,6
      IF (M-N) 792,791,792
  791 DO 793 JJ=M,6
      MJJ=(JJ-1)*JJ/2+M
      S(MJJ)=S(MJJ)/AUX(N)
  793 CONTINUE
      FM(N)=FM(N)/AUX(N)
      GO TO 771
  792 DO 770 JJ=M,6
      MJJ=(JJ-1)*JJ/2+M
      S(MJJ)=S(MJJ)-(AUX(M)/AUX(N))*AUX(JJ)
  770 CONTINUE
      FM(M)=  FM(M)-(AUX(M)/AUX(N))*RHN
  771 CONTINUE
C     WRITE (6,1902) L,(FM(MM),MM=1,6)
C1902 FORMAT (' EQUIV NODAL FORCES AFTER ROTATIONAL RELAXATION AT END No
C    1.',I2/' ',6E12.4)
   59 CONTINUE
CCCCCCCCCCCCCCCCCCCCCCC
      DO 859 L=1,2
      IF (LREL(L)) 859,859,860
  860 GO TO (861,862),L
  861 M=3
      ROTA(1,NOM)=FM(3)
      GO TO 863
  862 M=6
      ROTA(2,NOM)=FM(6)
  863 DO 870 JJ=M,6
      MJJ=(JJ-1)*JJ/2+M
      S(MJJ)=0.
  870 CONTINUE
      FM(M)=0.
  859 CONTINUE
C
CCCCCCCCCCCCCCCCCCCCC
      do 3 k=1,6
      if (fm(k)) 4,3,4
    3 continue
      go to 5
    4 if (ang) 11,12,11
   12 do 44 k=1,6
      gfm(k)=fm(k)
   44 continue
      go to 566
c  generate transposed of transformation matrix related to rotation
   11 do 32 j=1,36
      a(j)=0.
   32 continue
      do 33 j=1,2
      do 33 k=1,8,7
      l=k+21*(j-1)
      a(l)=cos(ang)
   33 continue
      do 34 j=2,7,5
      isign=(-1)**j
      do 34 k=1,2
      l=j+(k-1)*21
      a(l)=float(isign)*sin(ang)
   34 continue
      do 35 j=15,36,21
      a(j)=1.
   35 continue
c  premultiply original vector by transposed of transformation matrix
      do 1 i=1,6
      gfm(i)=0.
      do 1 j=1,6
      isuba=(j-1)*6+i
      gfm(i)=gfm(i)+a(isuba)*fm(j)
    1 continue
c  write nodal concentrations on the right hand side of the system
  566 do 70 k=1,3
      do 70 l=1,2
      kl=(l-1)*3+k
      go to (71,72),l
   71 isuba=3*ni-3+k
      go to 73
   72 isuba=3*nj-3+k
   73 rhs(isuba)=gfm(kl)+rhs(isuba)
   70 continue
    5 return
      end
c**********************************************************************
c*********************************************************************
      subroutine symo1 (jbw,g,a,nn,n,i,spdis)
c  to modify system of equations to account for specified displacement,
c  spdis, at node n, along direction x,y, or z, identified by value 1,2
c  or 3 of argument i. total number of nodes, with 3 degrees of freedom
c  each, is nn. right hand side vector is array a and the stiffness
c  matrix with upper band width jbw, is stored in compact form, upper
c  band only, as single subscripted array g, taking terms row-wise.
      dimension g(99999),a(3003),gg(303)
c  ordinal position of appropiate coordinate of displacement, nl
      nl=3*n-3+i
c  modification of terms along row nl
      is=(nl-1)*jbw+1
      g(is)=1.
      is1=is+1
      lim=is+jbw-1
c  save row nl of stiffness matrix, in array (gg(l),l=1,(jbw-1))
      do 503 kj=is1,lim
      mm=kj-is
      gg(mm)=g(kj)
  503 continue
      do 303 kj=is1,lim
      g(kj)=0.
  303 continue
      a(nl)=spdis
      nl1=nl-1
      if (nl1) 36,36,369
c  modification of terms in equations above row nl
  369 if (nl-jbw) 379,379,389
  379 lim=1
      go to 399
  389 lim=nl-jbw+1
  399 do 304 kj=lim,nl1
      kjp=nl-kj+1
      is=(kj-1)*jbw+kjp
      a(kj)=a(kj)-g(is)*spdis
      g(is)=0.
  304 continue
c  modification of right hand side, below row nl, if spdis is not zero
   36 if (spdis) 499,26,499
  499 if (nl-3*nn) 498,26,26
  498 nl1=nl+1
      lim=nl+jbw-1
      do 404 kj=nl1,lim
      if (kj-3*nn) 401,401,404
  401 is=kj-nl
      a(kj)=a(kj)-gg(is)*spdis
  404 continue
   26 continue
      return
      end
c**********************************************************************
c*********************************************************************
      subroutine symso (g,b,neq,jbw)
c  to solve symmetric and banded system of equations
c  neq=no. of equations - jbw= upper band width
c  b=right hand side transformed into vector of solutions
c  g=matrix of coefficients stored in compact form,upper band only,as
c  single subscripted array, taking terms  row-wise
      dimension g(99999),b(3003),c(303)
      n=0
cc forward elimination
  100 n=n+1
c  modification of the right hand side term, row n
      ns1=(n-1)*jbw+1
      if (g(ns1)) 65,75,65
   65 b(n)=b(n)/g(ns1)
      go to 85
   75 b(n)=0.
   85 continue
      if (n-neq) 150,300,150
c  c=vector to save terms of row n prior elimination of n th solution
c  modification of terms along row n before starting elimination
  150 do 220 k=2,jbw
      nsk=(n-1)*jbw+k
      c(k)=g(nsk)
      if (g(ns1)) 120,220,120
  120 g(nsk)=g(nsk)/g(ns1)
  220 continue
c  outer do loop to cover affected rows below row n
      do 260 l=2,jbw
      i=n+l-1
      if (neq-i) 260,240,240
  240 j=0
c  inner do loop to cover affected terms along row i
      do 250 k=l,jbw
      j=j+1
      isj=(i-1)*jbw+j
      nsk=(n-1)*jbw+k
      g(isj)=g(isj)-c(l)*g(nsk)
  250 continue
c  modification of right hand side term, row i
      b(i)=b(i)-c(l)*b(n)
  260 continue
      go to 100
cc backward substitution
  300 n=n-1
      if (n) 350,500,350
  350 do 400 k=2,jbw
      nsk=(n-1)*jbw+k
      l=n+k-1
      if (neq-l) 400,370,370
  370 b(n)=b(n)-g(nsk)*b(l)
  400 continue
      go to 300
  500 continue
      return
      end
c**********************************************************************
c*********************************************************************
      subroutine doutp (a,nn)
c  displacement output in plane frame analysis, 3 degrees of freedom per
c  node, at the rate of 2 nodes per printer line
c   a=complete list of displacements - nn=total number of nodes
      dimension a(3003)
      write (6,3)
    3 format   ( ' ',5x,'Output of nodal displacements in reference to
     1global axes'/)
      write (6,4)
    4 format (' ',2('node',2x,'displ.',6x,'displ.',6x,'displ.',4x)/' ',
     12(5x,'along  x',4x,'along  y',4x,'around  z',3x)/)
C     write (6,14)
      knt=0
      kod=0
      do 6 i=1,nn
      knt=knt+1
      kod=kod+1
      is1=3*i-2
      is2=3*i-1
      is3=3*i
      go to (21,22),kod
   21 write (6,31) i,a(is1),a(is2),a(is3)
   31 format (' ',i3,3(e11.4,1x))
      go to 66
   22 write (6,32) i,a(is1),a(is2),a(is3)
   32 format (' ',40x,i3,3(e11.4,1x))
   66 if ((knt+1)/2-knt/2) 6,75,6
   75 kod=0
c     write (6,14)
c  14 format (' ')
    6 continue
      WRITE (6,68)
   68 FORMAT (' ',/70('-'))
      write (6,69)
   69 format  ( ' ',5x,'OUTPUT OF SOIL REACTIONS,STRESSES AND TRANSVERSE
     1 DISPLACEMENTS')
      return
      end
c**********************************************************************
c*********************************************************************
      subroutine efpre (a,cops,rko,rlo,x,exp,rl,m,ang,fm,ff,y,NOM,LIBRE,
     1ROTA,AUX1,AUX2)
c  purpose- generate array ((ff(l,k)l=1,2),k=1,6) corresponding to beam
c  on elastic foundation nodal displacements(l=1) and nodal loads(l=2),
c  in reference to local axes
c  known values = stiffness matrix,array cops, node numbers m(1),m(2),
c  where m(1) is the smallest, angle ang which the local axes are rotate
c  with respect to global axes, fixed end forces and moments caused by
c  distributed load, array fm, and complete list of nodal displacements,
c  contained in array a
c  purpose- generate soil pressures, array y, along the span, in terms
c  of nodal displacements and soil modulus defined by law of variation
c  rko+x*(rlo+z)**exp, where rko,x,rlo, and exp are constants and z
c  represents coordinate of position along the span of length rl
c  soil modulus in force per unit area units,that is,beam width included
C NOM=ELEMENT NUMBER, LIBRE(L,NOM)=HINGING PARAMETER AT Lth END
      dimension ff(2,6),cops(21),a(3003),y(11),m(2),fm(6),LIBRE(2,1000)
     1,ROTA(2,1000),AUX1(6,1000),AUX2(6,1000)
c-element nodal displacements extracted from complete list in array a
      do 2 i=1,6
      ms=(i-1)/3+1
      idi=3*m(ms)+2*i/3-2*ms
      ff(1,i)=a(idi)
    2 continue
      WRITE (6,68)
   68 FORMAT (' ',70('-'))
C     write (6,69)
      WRITE (6,601) NOM,M(1),M(2),(FF(1,I),I=1,6)
  601 FORMAT (' ',5X,/' END DISPLACEMENTS,ELEM',I3,' ,INCIDENCES',2I6/
     1' ',6E13.4)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C CHECK HINGING AT ELEMENT ENDS
      IF (LIBRE(1,NOM)) 82,82,81
   81 FF(1,3)=ROTA(1,NOM)
C     WRITE (6,586) NOM,rota(1,nom)
C 586 FORMAT (' INITIAL ROTATION AT 1st END OF ELEM.',I3,'=',E14.4)
   82 IF (LIBRE(2,NOM)) 84,84,83
   83 FF(1,6)=ROTA(2,NOM)
C     WRITE (6,687) NOM,rota(2,nom)
C 687 FORMAT (' INITIAL ROTATION AT 2nd END OF ELEM.',I3,'=',E14.4)
   84 CONTINUE
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      IF (LIBRE(1,NOM)) 42,42,41
   41 IF (LIBRE(2,NOM)) 43,43,50
   43 DO 130 J=1,6
      IF (J-3) 131,130,131
  131 FF(1,3)=FF(1,3) - AUX1(J,NOM)*FF(1,J)
  130 CONTINUE
C
C     WRITE (6,651) NOM,(AUX1(JJ,NOM),JJ=1,6)
C 651 FORMAT (' ',4X,'THIRD ROW OF STIFFNESS MATRIX OF ELEM',I3/
C    1' ',6E12.4)
C     WRITE (6,86) NOM,rota(1,nom),FF(1,3)
C  86 FORMAT (' INIT.,FINAL ROTATION AT 1st END OF ELEM.',I3,'=',2E14.4)
C
      WRITE (6,86) NOM,FF(1,3)
   86 FORMAT (' FINAL ROTATION AT 1st END OF ELEM.',I3,'=',2E14.4)
      GO TO 50
   42 IF (LIBRE(2,NOM)) 50,50,44
   44 DO 140 J=1,6
      IF (J-6) 141,140,141
  141 FF(1,6)=FF(1,6) - AUX2(J,NOM)*FF(1,J)
  140 CONTINUE
C
C     WRITE (6,652) NOM,(AUX2(JJ,NOM),JJ=1,6)
C 652 FORMAT (' ',4X,'SIXTH ROW OF STIFFNESS MATRIX OF ELEM',I3/
C    1' ',6E12.4)
C
C     WRITE (6,87) NOM,rota(2,nom),FF(1,6)
C  87 FORMAT (' INIT.,FINAL ROTATION AT 2nd END OF ELEM.',I3,'=',2E14.4)
C
      WRITE (6,87) NOM,FF(1,6)
   87 FORMAT (' FINAL ROTATION AT 2nd END OF ELEM.',I3,'=',2E14.4)
   50 CONTINUE
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
c- calculate element end forces
      do 28 i=1,6
      ff(2,i)=0.
      do 92 j=1,6
      if (i-j) 32,32,31
   32 ij=j*(j-1)/2+i
      go to 29
   31 ij=i*(i-1)/2+j
   29 ff(2,i)=ff(2,i)+cops(ij)*ff(1,j)
   92 continue
   28 continue
c- transform nodal displacements and loads to local axes if needed
      if (ang) 71,72,71
   71 do 93 l=1,2
      do 93 i=1,4,3
      aux=ff(l,i)
      ff(l,i)=ff(l,i)*cos(ang)+ff(l,i+1)*sin(ang)
      ff(l,i+1)=ff(l,i+1)*cos(ang)-aux*sin(ang)
   93 continue
c- include fixed end forces and moments due to distributed load
   72 do 94 i=1,6
      ff(2,i)=ff(2,i)-fm(i)
   94 continue
c- check if soil reactions are developed
      if (rko) 62,61,62
   61 if (x) 62,63,62
   63 do 64 k=1,11
      y(k)=0.
   64 continue
      go to 99
c- calculate soil pressures along the span, array y
   62 do 11 k=1,11
      k1=k-1
      xn=float(k1)/10.
      y(k)=(1.-xn)**2*(1.+2.*xn)*ff(1,2)
      y(k)=y(k)+rl*xn*(1.-xn)**2*ff(1,3)
      y(k)=y(k)+(3.*xn**2-2.*xn**3)*ff(1,5)
      y(k)=y(k)-rl*xn**2*(1.-xn)*ff(1,6)
      if (exp) 8,10,8
    8 y(k)=y(k)*(rko+x*(rlo+xn*rl)**exp)
      go to 11
   10 y(k)=y(k)*(rko+x)
   11 continue
   99 continue
      return
      end
c**********************************************************************
c*********************************************************************
      subroutine cdevv (rko,rlo,x,exp,rl,k,co,c,de,vv)
c  purpose- calculate coefficients,co and array c,related to a point
c  located at distance, from left end,equal to k times one tenth of
c  span length,rl
c  purpose- generate influence coefficients for transverse displacement
c  and shear at above mentioned point,arrays de and vv respectively
c  soil modulus varation=rko+x*(rlo+z)**exp, in force per unit area
c  units, where rko,x,rlo,and exp are constants and z represents
c  coordinate of position of the point under consideration
      dimension c(6),de(4),vv(4)
      r=float(k)/10.
      e1=exp+1.
      co=((rlo+r*rl)**e1-rlo**e1)/(rl*e1)
      c(1)=(r*(rlo+r*rl)**e1-rlo*co)/(rl*(e1+1))
      do 112 l=2,6
      c(l)=(r**l*(rlo+r*rl)**e1-float(l)*rlo*c(l-1))/(rl*(e1+float(l)))
  112 continue
      de(1)=rko*rl**4*(r**4/24.-r**6/120.+r**7/420.)
      de(1)=de(1)+x*rl**4*(r**3*co/6.-0.5*r*r*c(1)+0.5*(r-r*r*r)*c(2)+
     1(1.5*r*r+r**3/3.-1./6.)*c(3)-(1.5*r+r*r)*c(4)+(0.5+r)*c(5)-c(6)/3.
     2)
      de(2)=rko*rl**5*(r**5/120.-r**6/180.+r**7/840.)
      de(2)=de(2)+x*rl**5*(r**3*c(1)/6.-(0.5*r*r+r**3/3.)*c(2)+(0.5*r+
     1r*r+r**3/6.)*c(3)-(1./6.+0.5*r*r+r)*c(4)+(1./3.+0.5*r)*c(5)-c(6)/6
     2.)
      de(3)=rko*rl**4*(r**6/120.-r**7/420.)
      de(3)=de(3)+x*rl**4*(0.5*r**3*c(2)-(1.5*r*r+r**3/3.)*c(3)+(1.5*r+
     1r*r)*c(4)-(0.5+r)*c(5)+c(6)/3.)
      de(4)=rko*rl**5*(-r**6/360.+r**7/840.)
      de(4)=de(4)+x*rl**5*(-r**3*c(2)/6.+(0.5*r*r+r**3/6.)*c(3)-(0.5*r+
     10.5*r*r)*c(4)+(1./6.+0.5*r)*c(5)-c(6)/6.)
      vv(1)=rko*rl*(r-r**3+r**4/2.)+x*rl*(co-3.*c(2)+2.*c(3))
      vv(2)=rko*rl*rl*(r*r/2.-2.*r**3/3.+r**4/4.)+x*rl*(c(1)-2.*c(2)+c(3
     1))*rl
      vv(3)=rko*rl*(r**3-r**4/2.)+x*rl*(3.*c(2)-2.*c(3))
      vv(4)=rko*rl*rl*(-r**3/3.+r**4/4.)+x*rl**2*(-c(2)+c(3))
      return
      end
c**********************************************************************
c*********************************************************************
      subroutine coslm (rko,rlo,x,exp,rl,k,co,c,sl,rm)
c purpose- generate influence coefficients for slope and moment at
c point located,from left end, distance equal to k times one tenth
c of span length,rl, arrays sl and rm, respectively
c  see subroutine cdevv for meaning of other arguments
      dimension c(6),sl(4),rm(4)
      r=float(k)/10.
      e1=exp+1.
      sl(1)=rko*rl**3*(r**3/6.-r**5/20.+r**6/60.)
      sl(1)=sl(1)+x*rl**3*(0.5*r*r*co-r*c(1)+0.5*(1.-3.*r*r)*c(2)+(3.*r+
     1r*r)*c(3)-(1.5+2.*r)*c(4)+c(5))
      sl(2)=rko*rl**4*(r**4/24.-r**5/30.+r**6/120.)
      sl(2)=sl(2)+x*rl**4*(0.5*r*r*c(1)-(r+r*r)*c(2)+(0.5+2.*r+0.5*r*r)*
     1c(3)-(1.+r)*c(4)+0.5*c(5))
      sl(3)=rko*rl**3*(r**5/20.-r**6/60.)
      sl(3)=sl(3)+x*rl**3*(1.5*r*r*c(2)-(3.*r+r*r)*c(3)+(1.5+2.*r)*c(4)-
     1c(5))
      sl(4)=rko*rl**4*(-r**5/60.+r**6/120.)
      sl(4)=sl(4)+x*rl**4*(-0.5*r*r*c(2)+(r+0.5*r*r)*c(3)-(0.5+r)*c(4)+
     10.5*c(5))
      rm(1)=rko*rl**2*(r*r/2.-r**4/4.+r**5/10.)
      rm(1)=rm(1)+x*rl*rl*(r*co-c(1)-3.*r*c(2)+(3.+2.*r)*c(3)-2.*c(4))
      rm(2)=rko*rl**3*(r**3/6.-r**4/6.+r**5/20.)
      rm(2)=rm(2)+x*rl**3*(r*c(1)-(1.+2.*r)*c(2)+(2.+r)*c(3)-c(4))
      rm(3)=rko*rl**2*(r**4/4.-r**5/10.)
      rm(3)=rm(3)+x*rl*rl*(3.*r*c(2)-(3.+2.*r)*c(3)+2.*c(4))
      rm(4)=rko*rl**3*(-r**4/12.+r**5/20.)
      rm(4)=rm(4)+x*rl**3*(-r*c(2)+(1.+r)*c(3)-c(4))
      return
      end
c**********************************************************************
c*********************************************************************
      subroutine resbm (ff,rl,ri,e,k,de,vv,sl,rm,disp,slop,shea,rmom,pa,
     1pb)
c- purpose- find shear,shea,moment,rmom,slope,slop,and transverse deflec
c  tion,disp, at a point located k times one tenth of span rl,from local
c  origin of coordinates, in a beam on elastic foundation
c- array (ff(1,l),l=1,6) represents nodal displacements and array (ff(2,
c  l),l=1,6) stands for generalized forces in reference to local axes
c- l=1,2 and 3 correspond to axial,transverse and rotational coordinates
c  of displacement at local origin - l=4,5,6 same but at the other end
c- e,ri=beam modulus of elasticity and moment of inertia
c- pa,pb=values of distributed load at origin and at other end of the
c  beam, linear variation assumed
c- arrays vv,rm,sl,de, are influence coefficients for shear,moment,slope
c  and deflection related to nodal displacements number 2,3,5 and 6
      dimension vv(4),rm(4),sl(4),de(4),ff(2,6),disp(10),shea(10),slop(1
     10),rmom(10)
      r=float(k)/10.
      shea(k)=ff(2,2)+pa*rl*r+(pb-pa)*rl*r**2/2.
      rmom(k)=-ff(2,3)+ff(2,2)*rl*r+pa*(rl*r)**2/2.+(pb-pa)*r*(rl*r)**2/
     16.
      slop(k)=ff(1,3)+ff(2,2)*(r*rl)**2/(2.*e*ri)-ff(2,3)*r*rl/(e*ri)+
     1pa*(rl*r)**3/(6.*e*ri)+(pb-pa)*r*(rl*r)**3/(24.*e*ri)
      disp(k)=ff(1,2)+ff(2,2)*(r*rl)**3/(6.*e*ri)+ff(1,3)*r*rl-ff(2,3)*(
     1r*rl)**2/(2.*e*ri)+pa*(rl*r)**4/(24.*e*ri)+(pb-pa)*r*(rl*r)**4/(12
     20.*e*ri)
      do 115 l=1,4
      ll=(l+1)/2
      ll=ll+l
      disp(k)=disp(k)-de(l)*ff(1,ll)/(e*ri)
      slop(k)=slop(k)-sl(l)*ff(1,ll)/(e*ri)
      shea(k)=shea(k)-vv(l)*ff(1,ll)
      rmom(k)=rmom(k)-rm(l)*ff(1,ll)
  115 continue
      return
      end
c**********************************************************************
c*********************************************************************
      subroutine boutp(nom,m,rl,y,ff,shea,rmom,disp,GLOX,CORTE,OUTM,XTOT
     1,OUTD)
c- output of soil reactions,stresses and displacements in a beam on
c  elastic foundation
      dimension m(2),y(11),ff(2,6),shea(10),rmom(10),disp(10),pos(11)
      dimension corte(11),outm(11),outd(11),GLOX(1000),XTOT(11)
C     write (6,111)
C 111 format (' ',70(' -'))
      write (6,64) nom,(m(l),l=1,2),rl
   64 format(/' MEMBER',i3,', FROM NODE',i3,', TO NODE',i3,' - LENGTH =
     1',f6.2,' ft'/)
      NOD1=M(1)
      do 59 jj=1,11
      pos(jj)=float(jj-1)/10.
      XTOT(JJ) = GLOX(NOD1) + POS(JJ)*RL
   59 continue
      do 973 l=1,11
  973 y(l)=-y(l)
      corte(1)=ff(2,2)
      outm(1)=-ff(2,3)
      outd(1)=ff(1,2)
      do 974 l=2,11
      corte(l)=shea(l-1)
      outm(l)=rmom(l-1)
  974 outd(l)=disp(l-1)
c
      do 99 kk=1,2
      if (kk-1) 91,91,92
C
   91 l1=1
      l2=6
      write (6,94)
   94 format ('  Left half of span,at tenth points of length')
      write (6,198)
  198 format (' ',10x,'0.0 Span  0.1 Span  0.2 Span  0.3 Span  0.4 Span
     1 0.5 Span')     
      go to 398
c
   92 l1=6
      l2=11
      write (6,95)
   95 format (' Right half of span,at tenth points of length')
      write (6,298)
  298 format (' ',10x,'0.5 Span  0.6 Span  0.7 Span  0.8 Span  0.9 Span
     1 1.0 Span')
c
c  98 write (6,63) (pos(l),l=l1,l2)
c  63 format (' ',9x,6(5x,'span',1x)/'+',9x,6(1x,f3.1,6x))
C
  398 write (6,66) (y(l),l=l1,l2)
   66 format (' soil,k/ft',6(f9.3,1x))
      write (6,67) (corte(l),l=l1,l2)
   67 format (' shear,k',2x,6(f9.2,1x))
      write (6,68) (outm(l),l=l1,l2)
   68 format (' bmom,kft',1x,6(f9.2,1x))
      write (6,69) (outd(l),l=l1,l2)
   69 format (' tdisp,ft',1x,6(f9.5,1x))
      write (6,70) ff(2,1)
   70 format (' axial,k',2x,f9.2,2x,'... throughout the span'/)
   99 continue
      return
      end

