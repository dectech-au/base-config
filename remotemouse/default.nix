{ lib
, stdenv
, fetchzip
, patchelf

, glib
, dbus
, zlib
, freetype
, fontconfig
, libxkbcommon
, libGL
, alsa-lib
, xorg
, xdotool ? null
, xhost   ? xorg.xhost
}:

let
  xdoBin    = lib.optionalString (xdotool != null) "${lib.makeBinPath [ xdotool ]}";
  xhostBin  = lib.makeBinPath [ xhost ];

  # host libs we need in *addition* to vendor bundle (do NOT add Qt here; vendor ships its own)
  runtimeLibPath = lib.makeLibraryPath [
    glib dbus zlib freetype fontconfig libxkbcommon libGL alsa-lib
    stdenv.cc.cc.lib stdenv.cc.libc
    xorg.libX11 xorg.libXext xorg.libXrender xorg.libXtst xorg.libXi
    xorg.libXcursor xorg.libXrandr xorg.libSM xorg.libICE xorg.libxcb
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

  nativeBuildInputs = [ patchelf ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/remotemouse
    cp -r RemoteMouse lib images $out/opt/remotemouse/

    # icons
    if [ -f images/RemoteMouse.png ]; then
      mkdir -p $out/share/pixmaps
      cp images/RemoteMouse.png $out/share/pixmaps/remotemouse.png
    fi

    # desktop entry
    mkdir -p $out/share/applications
    cat >$out/share/applications/remotemouse.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Remote Mouse
Comment=Control this PC from your phone
Exec=remotemouse
Icon=remotemouse
Terminal=false
Categories=Utility;
EOF

    # Create wrapper
    mkdir -p $out/bin

    cat >$out/bin/remotemouse <<'EOSH'
#!/usr/bin/env bash
set -euo pipefail

vendor="@out@/opt/remotemouse"
libdir="$vendor/lib"

# Fallback XAUTHORITY if unset or unreadable
if [ -z "${XAUTHORITY:-}" ] || [ ! -r "$XAUTHORITY" ]; then
  if [ -r "$HOME/.Xauthority" ]; then
    export XAUTHORITY="$HOME/.Xauthority"
  else
    guess=$(ls /run/user/$(id -u)/xauth_* 2>/dev/null | head -n1 || true)
    [ -n "$guess" ] && export XAUTHORITY="$guess"
  fi
fi

# Optional selective X access (ignore failure if xhost missing)
"@xhostBin@"/xhost +SI:localuser:"$USER" >/dev/null 2>&1 || true

# Runtime env
export LD_LIBRARY_PATH="$libdir:$libdir/PyQt5:$libdir/PyQt5/Qt5/lib:@runtimeLibPath@${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PYTHONHOME="$libdir"
export PYTHONPATH="$libdir"
export QT_PLUGIN_PATH="$libdir/PyQt5/Qt5/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="$libdir/PyQt5/Qt5/plugins/platforms"
export QML2_IMPORT_PATH="$libdir/PyQt5/Qt5/qml"

# Optional: PATH injection for xdotool if shipped
if [ -n "@xdoBin@" ]; then
  export PATH="@xdoBin@:$PATH"
fi

cd "$vendor"
exec "$vendor/RemoteMouse" "$@"
EOSH

    substituteInPlace $out/bin/remotemouse \
      --subst-var out \
      --subst-var-by xhostBin ${xhostBin} \
      --subst-var-by runtimeLibPath ${runtimeLibPath} \
      --subst-var-by xdoBin "${xdoBin}"

    chmod +x $out/bin/remotemouse

    runHook postInstall
  '';

  postFixup = ''
    echo "Patching RemoteMouse ELF..."
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
             --set-rpath "$out/opt/remotemouse/lib:$out/opt/remotemouse/lib/PyQt5:$out/opt/remotemouse/lib/PyQt5/Qt5/lib:${runtimeLibPath}" \
             $out/opt/remotemouse/RemoteMouse || true

    for so in $out/opt/remotemouse/lib/*.so*; do
      [ -e "$so" ] || continue
      patchelf --set-rpath "$out/opt/remotemouse/lib:$out/opt/remotemouse/lib/PyQt5:$out/opt/remotemouse/lib/PyQt5/Qt5/lib:${runtimeLibPath}" "$so" || true
    done
  '';

  dontPatchELF = true; # we patched manually
  dontStrip = true;

  meta = with lib; {
    description = "Remote Mouse proprietary binary packaged for NixOS (X11)";
    homepage = "https://www.remotemouse.net/";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
  };
}
