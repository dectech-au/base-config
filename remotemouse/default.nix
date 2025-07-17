@@
- , makeWrapper
- , xdotool ? null  # optional; see note below
+ , makeWrapper
+ , patchelf
+ , libX11
+ , libXtst
+ , libXi
+ , alsa-lib
+ , xdotool ? null
@@
-in
-stdenv.mkDerivation rec {
+  runtimeLibPath = lib.makeLibraryPath [
+    libX11 libXtst libXi alsa-lib
+    stdenv.cc.cc.lib
+    stdenv.cc.libc
+  ];
+in stdenv.mkDerivation rec {
@@
-  nativeBuildInputs = [ makeWrapper ];
+  nativeBuildInputs = [ makeWrapper patchelf ];
@@
-  dontPatchELF = true;  # vendor binary ships working RPATH relative to $ORIGIN
-  dontStrip = true;     # keep their binary intact
+  postFixup = ''
+    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
+             --set-rpath "$out/opt/remotemouse/lib:${runtimeLibPath}" \
+             $out/opt/remotemouse/RemoteMouse || true
+    for so in $out/opt/remotemouse/lib/*.so*; do
+      [ -e "$so" ] || continue
+      patchelf --set-rpath "$out/opt/remotemouse/lib:${runtimeLibPath}" "$so" || true
+    done
+  '';
+  dontPatchELF = true;
+  dontStrip = true;
