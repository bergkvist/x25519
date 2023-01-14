{ system ? builtins.currentSystem
, lock ? builtins.fromTOML (builtins.readFile ./default.nix.lock)
, pkgs ? import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${lock.nixpkgs.commit}.tar.gz";
    sha256 = lock.nixpkgs.sha256;
  }) {}
, projectRoot ? toString ./.
}:
let
  python = pkgs.python310;
  libsodium = pkgs.libsodium.overrideAttrs(old: { patches = old.patches ++ [ ./no_clamp.patch ]; doCheck = false; });
  pynacl = (python.pkgs.pynacl.override { inherit libsodium; })
            .overridePythonAttrs (old: { doCheck = false; });
  pythonEnv = pkgs.callPackage ./python-env.nix { inherit python projectRoot; };
in
{ inherit pkgs libsodium python pythonEnv pynacl projectRoot; }
