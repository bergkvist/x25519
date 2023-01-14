with (import ./nix { projectRoot = toString ./.; });
pkgs.mkShell {
  buildInputs = [
    libsodium
    pynacl
    pythonEnv
    pkgs.nodejs-16_x
  ];
}
