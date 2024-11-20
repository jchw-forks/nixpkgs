{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  zlib,
  libjpeg,
  libpng,
  fontconfig,
  freetype,
  libxkbcommon,
  libX11,
  libXext,
  libXinerama,
  libXfixes,
  libXcursor,
  libXft,
  libXrender,
  ApplicationServices,
  Carbon,
  Cocoa,
  libGL,
  libGLU,
  glew,
  OpenGL,
  cairo,
  pango,
  doxygen,
  graphviz,
  wayland,
  wayland-protocols,
  wayland-scanner,
  withShared ? !stdenv.hostPlatform.isStatic,
}:

let
  version = "1.4.0-1";
  onOff = value: if value then "ON" else "OFF";
in
stdenv.mkDerivation {
  pname = "fltk";
  inherit version;

  src = fetchFromGitHub {
    owner = "fltk";
    repo = "fltk";
    rev = "release-${version}";
    hash = "sha256-iyuMIO5YyXNmbKmx1SLMFFN2J1EC3GN+Wd0laZlog2g=";
  };

  outputs = [
    "out"
    "bin"
    "doc"
  ];

  # Manually move example & test binaries to $bin to avoid cyclic dependencies on dev binaries
  outputBin = "out";

  postPatch = ''
    patchShebangs documentation/make_*
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    doxygen
    graphviz
    wayland-scanner
  ];

  buildInputs =
    [
      glew
      libxkbcommon
      wayland
      wayland-protocols
      cairo
      libjpeg
      libpng
      zlib
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      freetype
      fontconfig
      libX11
      libXext
      libXinerama
      libXfixes
      libXcursor
      libXft
      libXrender
      pango
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      ApplicationServices
      Carbon
      Cocoa
      OpenGL
    ]
    ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
      libGL
      libGLU
    ];

  cmakeFlags = [
    # Common
    "-DFLTK_BUILD_SHARED_LIBS=${onOff withShared}"
    "-DFLTK_USE_SYSTEM_ZLIB=ON"
    "-DFLTK_USE_SYSTEM_LIBJPEG=ON"
    "-DFLTK_USE_SYSTEM_LIBPNG=ON"

    # Examples & Tests
    "-DFLTK_BUILD_EXAMPLES=ON"
    "-DFLTK_BUILD_TEST=ON"

    # Docs
    "-DFLTK_BUILD_HTML_DOCS=ON"
    "-DFLTK_BUILD_PDF_DOCS=OFF"
    "-DFLTK_INSTALL_HTML_DOCS=ON"
    "-DFLTK_INSTALL_PDF_DOCS=OFF"
    "-DFLTK_INCLUDE_DRIVER_DOCS=ON"

    # RPATH of binary /nix/store/.../bin/... contains a forbidden reference to /build/
    "-DCMAKE_SKIP_BUILD_RPATH=ON"
  ];

  postBuild = ''
    make docs
  '';

  postInstall =
    ''
      mkdir -p $bin/bin
      mv bin/{test,examples}/* $bin/bin/
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      mkdir -p $out/Library/Frameworks
      mv $out{,/Library/Frameworks}/FLTK.framework

      moveAppBundles() {
        echo "Moving and symlinking $1"
        appname="$(basename "$1")"
        binname="$(basename "$(find "$1"/Contents/MacOS/ -type f -executable | head -n1)")"
        curpath="$(dirname "$1")"

        mkdir -p "$curpath"/../Applications/
        mv "$1" "$curpath"/../Applications/
        [ -f "$curpath"/"$binname" ] && rm "$curpath"/"$binname"
        ln -s ../Applications/"$appname"/Contents/MacOS/"$binname" "$curpath"/"$binname"
      }

      rm $out/bin/fluid.icns
      for app in $out/bin/*.app $bin/bin/*.app; do
        moveAppBundles "$app"
      done
    '';

  postFixup = ''
    substituteInPlace $out/bin/fltk-config \
      --replace "/$out/" "/"
  '';

  meta = with lib; {
    description = "C++ cross-platform lightweight GUI library";
    homepage = "https://www.fltk.org";
    platforms = platforms.unix;
    # LGPL2 with static linking exception
    # https://www.fltk.org/COPYING.php
    license = licenses.lgpl2Only;
  };
}
