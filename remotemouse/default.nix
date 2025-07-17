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
}:

let
  xdoPath = lib.optionalString (xdotool != null) "${lib.makeBinPath [ xdotool ]}";

  # host-side libs Qt/xcb may reach for (NO qt5.* here; use vendor's Qt)
  runtimeLibPath = lib.makeLibraryPath [
    glib dbus zlib freetype fontconfig libxkbcommon libGL alsa-lib
    stdenv.cc.cc.lib stdenv.cc.libc

    # Core X + extensions
    xorg.libX11 xorg.libXext xorg.libXrender xorg.libXtst xorg.libXi
    xorg.libXcursor xorg.libXrandr xorg.libSM xorg.libICE
    xorg.libxcb
    xorg.xcbutil
    xorg.xcbutilwm          # provides libxcb-icccm.so.*
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilcursor
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

    # optional desktop integration
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

    if [ -f images/RemoteMouse.png ]; then
      mkdir -p $out/share/pixmaps
      cp images/RemoteMouse.png $out/share/pixmaps/remotemouse.png
    fi

    # Paths for wrapper env
    vendorLib="$out/opt/remotemouse/lib"
    vendorQtLib="$vendorLib/PyQt5/Qt5/lib"
    vendorQtPlugins="$vendorLib/PyQt5/Qt5/plugins"
    vendorQtQml="$vendorLib/PyQt5/Qt5/qml"

    # Generate wrapper
    mkdir -p $out/bin
    makeWrapper $out/opt/remotemouse/RemoteMouse $out/bin/remotemouse \
      --chdir $out/opt/remotemouse \
      --prefix LD_LIBRARY_PATH : "$vendorLib:$vendorLib/PyQt5:$vendorQtLib:${runtimeLibPath}" \
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

    # patch top-level vendor libs (shallow)
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
