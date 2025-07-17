{ lib
, stdenv
, fetchzip
, makeWrapper
, patchelf
, libX11
, libXtst
, libXi
, alsa-lib
, xdotool ? null
}:

let
  xdoPath = lib.optionalString (xdotool != null) "${lib.makeBinPath [ xdotool ]}";
  # libs RemoteMouse might dlopen or link against; extend if it complains
  runtimeLibPath = lib.makeLibraryPath [
    libX11
    libXtst
    libXi
    alsa-lib
    stdenv.cc.cc.lib   # libstdc++ etc.; safe include
    stdenv.cc.libc     # glibc runtime (ld, libc.so, etc.)
  ];
in
stdenv.mkDerivation rec {
  pname = "remotemouse";
  version = "2023-01-25";

  src = fetchzip {
    url = "https://www.remotemouse.net/downloads/linux/RemoteMouse_x86_64.zip";
    hash = "sha256-kmASvBKJW9Q1Z7ivcuKpZTBZA9LDWaHQerqMcm+tai4=";
    stripRoot = false;
  };

  nativeBuildInputs = [ makeWrapper patchelf ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/remotemouse
    cp -r RemoteMouse lib images $out/opt/remotemouse/

    mkdir -p $out/share/applications
    cat >$out/share/applications/remotemouse.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Remote Mouse
Comment=Control this PC from your phone
Exec=remotemouse
Icon=remotemouse
Terminal=false
Categories=Utility;
EOF

    if [ -f images/RemoteMouse.png ]; then
      mkdir -p $out/share/pixmaps
      cp images/RemoteMouse.png $out/share/pixmaps/remotemouse.png
    fi

    mkdir -p $out/bin
    makeWrapper $out/opt/remotemouse/RemoteMouse $out/bin/remotemouse \
      --chdir $out/opt/remotemouse \
      ${lib.optionalString (xdoPath != "") "--prefix PATH : ${xdoPath}"}

    runHook postInstall
  '';

  # Patch after install so we reference store paths correctly.
  postFixup = ''
    echo "Patching RemoteMouse ELF..."
    patchelf \
      --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
      --set-rpath "$out/opt/remotemouse/lib:${runtimeLibPath}" \
      $out/opt/remotemouse/RemoteMouse || true

    # Also patch bundled shared objects (belt-and-suspenders)
    for so in $out/opt/remotemouse/lib/*.so*; do
      [ -e "$so" ] || continue
      patchelf --set-rpath "$out/opt/remotemouse/lib:${runtimeLibPath}" "$so" || true
    done
  '';

  # let patchelf do its thing; do NOT suppress
  dontPatchELF = true;  # we explicitly patch in postFixup; leave auto phase off
  dontStrip   = true;

  meta = with lib; {
    description = "Remote Mouse proprietary binary packaged for NixOS (X11)";
    homepage = "https://www.remotemouse.net/";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
  };
}
