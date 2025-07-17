{ lib
, stdenv
, fetchzip
, makeWrapper
, xdotool ? null  # optional; see note below
}:

let
  xdoPath = lib.optionalString (xdotool != null) "${lib.makeBinPath [ xdotool ]}";
in
stdenv.mkDerivation rec {
  pname = "remotemouse";
  # Upstream has no real version; use date of current published zip.
  version = "2023-01-25";

  src = fetchzip {
    url = "https://www.remotemouse.net/downloads/linux/RemoteMouse_x86_64.zip";
    hash = "sha256-eG0CG+ZxVRBPcL+0/zVoAFXYORhPdFniBkcima4F6Ww=";
    stripRoot = false;  # zip extracts files at top-level
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/remotemouse
    cp -r RemoteMouse lib images $out/opt/remotemouse/

    # desktop file (optional)
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

    # icon if present
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

  dontPatchELF = true;  # vendor binary ships working RPATH relative to $ORIGIN
  dontStrip = true;     # keep their binary intact

  meta = with lib; {
    description = "Remote Mouse proprietary binary packaged for NixOS (X11 desktop helper)";
    homepage = "https://www.remotemouse.net/";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
  };
}
