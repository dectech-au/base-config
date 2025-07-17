{ lib
, stdenv
, fetchzip
, makeWrapper
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
, xhost ? xorg.xhost
}:

let
  xdoPath   = lib.optionalString (xdotool != null) "${lib.makeBinPath [ xdotool ]}";
  xhostPath = lib.makeBinPath [ xhost ];

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

  nativeBuildInputs = [ makeWrapper patchelf ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/remotemouse
    cp -r RemoteMouse lib images $out/opt/remotemouse/

    # icon
    if [ -f images/RemoteMouse.png ]; then
      mkdir -p $out/share/pixmaps
      cp images/RemoteMouse.png $out/share/pixmaps/remotemouse.png
    fi

    # desktop file
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

    # vendor paths
    vendorLib="$out/opt/remotemouse/lib"
    vendorQtLib="$vendorLib/PyQt5/Qt5/lib"
    vendorQtPlugins="$vendorLib/PyQt5/Qt5/plugins"
    vendorQtQml="$vendorLib/PyQt5/Qt5/qml"

    mkdir -p $out/bin
    makeWrapper $out/opt/remotemouse/RemoteMouse $out/bin/remotemouse \
      --chdir $out/opt/remotemouse \
      --run 'if [ -z "${XAUTHORITY:-}" ] || [ ! -r "$XAUTHORITY" ]; then for f in "$HOME/.Xauthority" /run/user/$(id -u)/xauth_*; do [ -r "$f" ] && export XAUTHORITY="$f" && break; done; fi' \
      --run '"${xhostPath}"/xhost +SI:localuser:$USER >/dev/null 2>&1 || true' \
      --set LD_LIBRARY_PATH "$vendorLib:$vendorLib/PyQt5:$vendorQtLib:${runtimeLibPath}" \
      --set PYTHONHOME "$vendorLib" \
      --set PYTHONPATH "$vendorLib" \
      --set QT_PLUGIN_PATH "$vendorQtPlugins" \
      --set QT_QPA_PLATFORM_PLUGIN_PATH "$vendorQtPlugins/platforms" \
      --set QML2_IMPORT_PATH "$vendorQtQml" \
      ${lib.optionalString (xdoPath != "") "--prefix PATH : ${xdoPath}"}

    runHook postInstall
  '';

  postFixup = ''
    echo "Patching RemoteMouse ELF..."
    patchelf \
      --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
      --set-rpath "$out/opt/remotemouse/lib:$out/opt/remotemouse/lib/PyQt5:$out/opt/remotemouse/lib/PyQt5/Qt5/lib:${runtimeLibPath}" \
      $out/opt/remotemouse/RemoteMouse || true

    for so in $out/opt/remotemouse/lib/*.so*; do
      [ -e "$so" ] || continue
      patchelf --set-rpath "$out/opt/remotemouse/lib:$out/opt/remotemouse/lib/PyQt5:$out/opt/remotemouse/lib/PyQt5/Qt5/lib:${runtimeLibPath}" "$so" || true
    done
  '';

  dontPatchELF = true;
  dontStrip = true;

  meta = with lib; {
    description = "Remote Mouse proprietary binary packaged for NixOS (X11)";
    homepage = "https://www.remotemouse.net/";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
  };
}
