{ pkgs
, python ? pkgs.python3
, projectRoot
}:
let
  pythonModules = "${toString projectRoot}/python_modules";
  pipPrefix = "${pythonModules}/pip";
  libraryPath = pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.zlib ];
  propagatedBuildInputs = builtins.concatStringsSep " " (
    pkgs.lib.optionals pkgs.stdenv.isDarwin [
      pkgs.darwin.apple_sdk.frameworks.CoreServices
      pkgs.darwin.apple_sdk.frameworks.Cocoa
    ]
  );
in
pkgs.runCommand "${python.name}-wrapped" { buildInputs = [ pkgs.makeBinaryWrapper ]; } ''
  mkdir -p "$out/bin"
  mkdir -p "$out/nix-support"
  echo "export PATH=\"${pipPrefix}/bin\"" > "$out/nix-support/setup-hook"
  echo "${propagatedBuildInputs}" > $out/nix-support/propagated-build-inputs
  cd "${python}/bin" || exit 1
  for FILE in *; do
    makeWrapper "${python}/bin/$FILE" "$out/bin/$FILE" \
      --suffix LD_LIBRARY_PATH ":" "${libraryPath}" \
      --set PIP_DISABLE_PIP_VERSION_CHECK 1 \
      --prefix PYTHONPATH ":" "${python.pkgs.pip}/lib/${python.libPrefix}/site-packages" \
      --set-default NIX_PYTHONEXECUTABLE "$out/bin/python" \
      --unset PYTHONEXECUTABLE \
      --prefix PYTHONPATH ":" "${pipPrefix}/lib/${python.libPrefix}/site-packages" \
      --set-default PIP_PREFIX "${pipPrefix}" \
      --set-default IPYTHONDIR "${pythonModules}/ipython" \
      --set-default JUPYTER_CONFIG_DIR "${pythonModules}/jupyter/config" \
      --set-default JUPYTER_DATA_DIR "${pythonModules}/jupyter/data" \
      --set-default JUPYTERLAB_DIR "${pythonModules}/jupyter/lab"
  done
  cd "${python.pkgs.pip}/bin" || exit 1
  for FILE in *; do
    makeWrapper "${python.pkgs.pip}/bin/$FILE" "$out/bin/$FILE" \
      --set PIP_DISABLE_PIP_VERSION_CHECK 1 \
      --set-default NIX_PYTHONEXECUTABLE "$out/bin/python" \
      --unset PYTHONEXECUTABLE \
      --set-default PIP_PREFIX "${pipPrefix}" \
      --prefix PYTHONPATH ":" "${python.pkgs.pip}/lib/${python.libPrefix}/site-packages" \
      --prefix PYTHONPATH ":" "${pipPrefix}/lib/${python.libPrefix}/site-packages"
  done
''
