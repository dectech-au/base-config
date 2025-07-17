{ lib
, stdenv
, fetchzip
, makeWrapper
, patchelf

# Core runtime
, glib
, dbus
, zlib
, freetype
, fontconfig
, libxkbcommon
, libGL
, libGLU ? null

# X11 bits
, xorg
, alsa-lib

# Qt5 (PyQt5 bindings in bundle need these)
, libsForQt5

# optional
, xdotool ? null
}:

let
  inherit (libsForQt5) qtbase qtmultimedia qtdeclarative qtsvg qttools qtwebsockets qtserialport qtwayland;

  qtLibs = [
    qtbase qtmultimedia qtdeclarative qtsvg qttools qtwebsockets qtserialport qtwayland
  ];

  xdoPath = lib.optionalString (xdotool != null) "${lib.makeBinPath [ xdotool ]}";

  runtimeLibPath = lib.makeLibraryPath (
    [
      glib dbus zlib freetype fontconfig libxkbcommon libGL alsa-lib
      stdenv.cc.cc.lib stdenv.cc.libc
      xorg.libX11 xorg.libXtst xorg.libXi xorg.libXcursor xorg.libXrandr
    ]
    ++ qtLibs
    ++ lib.optional (libGLU != null) libGLU
  );

  qtPluginPath = "${qtbase.qtPluginPrefix or "${qtbase}/lib/qt-5/plugins"}";
  qtQmlPath    = "${qtdeclarative.dev or qtdeclarative}/lib/qt-5/qml";
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
      --set LD_LIBRARY_PATH "$out/opt/remotemouse/lib:${runtimeLibPath}" \
      --set PYTHONHOME "$out/opt/remotemouse/lib" \
      --set PYTHONPATH "$out/opt/remotemouse/lib" \
      --set QT_PLUGIN_PATH "${qtPluginPath}" \
      --set QML2_IMPORT_PATH "${qtQmlPath}" \
      ${lib.optionalString (xdoPath != "") "--prefix PATH : ${xdoPath}"}

    runHook postInstall
  '';

  postFixup = ''
    echo "Patching RemoteMouse ELF..."
    patchelf \
      --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
      --set-rpath "$out/opt/remotemouse/lib:${runtimeLibPath}" \
      $out/opt/remotemouse/RemoteMouse || true

    for so in $out/opt/remotemouse/lib/*.so*; do
      [ -e "$so" ] || continue
      patchelf --set-rpath "$out/opt/remotemouse/lib:${runtimeLibPath}" "$so" || true
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
