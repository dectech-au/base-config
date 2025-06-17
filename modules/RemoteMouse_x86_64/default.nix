{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "remotemouse";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [
    pkgs.makeWrapper
  ];

  buildInputs = [
    pkgs.qt5.qtbase
  ];

  buildPhase = ''echo "Skipping build, no Makefile or build"''; # no build

  installPhase = ''
    mkdir -p $out/bin
    cp RemoteMouse $out/bin/RemoteMouse.real
  '';

  dontWrapQtApps = true; # disable automatic qt wrapping

  postInstall = ''
    wrapProgram $out/bin/RemoteMouse.real \
      --prefix LD_LIBRARY_PATH : ${pkgs.qt5.qtbase.out}/lib \
      --set QT_QPA_PLATFORM_PLUGIN_PATH ${pkgs.qt5.qtbase.out}/lib/qt5/plugins/platforms
    mv $out/bin/RemoteMouse.real $out/bin/RemoteMouse
  '';
}

