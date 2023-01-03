{
  stdenv, src,
  bash, m4, flex, bison,
  fftw, mpi, scotch, boost, cgal, zlib
}:

stdenv.mkDerivation {
  name = "openfoam";

  inherit src;

  nativeBuildInputs = [ bash m4 flex bison ];
  buildInputs = [ fftw mpi scotch boost cgal zlib ];

  patches = [ ./fix-bash.patch ];
  postPatch = ''
    for f in \
      bin/foamGetDict \
      etc/openfoam \
      wmake/scripts/* \
      wmake/wmake \
      wmake/wmakeCollect \
      wmake/wmakeLnIncludeAll
    do
      substituteInPlace $f --replace /bin/bash ${bash}/bin/bash
    done
  '';

  configurePhase = ''
    set -x
    build="$(pwd)"
    export FOAM_APP=$build/applications
    export FOAM_SOLVERS=$build/applications/solvers
    export FOAM_APPBIN=$build/platforms/linux64Gcc/bin
    export FOAM_LIBBIN=$build/platforms/linux64Gcc/lib
    export FOAM_EXT_LIBBIN=$build/platforms/linux64Gcc/lib
    export FOAM_MPI=openmpi-system
    export FOAM_RUN=$build/run
    export FOAM_SRC=$build/src
    export FOAM_ETC=$build/etc
    export FOAM_USER_APPBIN=$build/platforms/linux64Gcc/bin
    export FOAM_USER_LIBBIN=$build/platforms/linux64Gcc/lib
    export FOAM_EXTRA_CXXFLAGS="-DFOAM_CONFIGURED_PROJECT_DIR=\\\"${placeholder "out"}\\\""
    export MPI_ARCH_PATH=/usr/include/openmpi
    export WM_ARCH=linux64
    export WM_LABEL_SIZE=32
    export WM_LABEL_OPTION=Int32
    export WM_COMPILER=Gcc
    export WM_COMPILER_LIB_ARCH=64
    export WM_COMPILE_OPTION=Opt
    export WM_DIR=$build/wmake
    export WM_OPTIONS=linux64Gcc
    export WM_PRECISION_OPTION=DP
    export WM_PROJECT=OpenFOAM
    export WM_PROJECT_DIR=$build
    export WM_PROJECT_USER_DIR=$build/debian/tmp
    export WM_PROJECT_VERSION="$(bin/foamEtcFile -show-api)"
    export WM_NCOMPPROCS=$CORES
    export gperftools_install=$build/platforms/linux64Gcc
    export WM_MPLIB=SYSTEMOPENMPI
    unset FOAMY_HEX_MESH

    bin/tools/foamConfigurePaths \
        -boost boost-system \
        -cgal  cgal-system \
        -fftw  fftw-system \
        -kahip kahip-none \
        -scotch scotch-system
  '';
  buildPhase = ''
    LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$build/platforms/linux64Gcc/lib/openmpi-system:$build/platforms/linux64Gcc/lib:$build/platforms/linux64Gcc/lib/dummy" \
      PATH="$PATH:$build/wmake" \
      ./Allwmake -j$CORES -q
  '';
  installPhase = ''
    find
    mkdir -p $out
    cp -Ra ./platforms/linux64Gcc/lib $out
    cp -Ra ./platforms/linux64Gcc/lib/dummy/* $out/lib
    cp -Ra ./platforms/linux64Gcc/lib/openmpi-system/* $out/lib
    cp -Ra ./platforms/linux64Gcc/bin $out
    cp -Ra ./etc $out
  '';
}

