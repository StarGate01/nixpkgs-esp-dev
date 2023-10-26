# When updating to a newer version, check if the version of `esp32*-toolchain-bin.nix` also needs to be updated.
{ rev ? "v4.4.1"
, sha256 ? "sha256-b5sDQcw7L218jN4KIMTFjc2nI1fOtvNak1uTdDS6H90="
, stdenv
, lib
, fetchFromGitHub
, mach-nix
}:

let
  src = fetchFromGitHub {
    owner = "StarGate01";
    repo = "esp-idf";
    rev = "eddde85f6bf05e89b388fa56e076b9ba51ea43d6";
    sha256 = sha256;
    fetchSubmodules = true;
  };

  pythonEnv =
    let
      # Remove things from requirements.txt that aren't necessary and mach-nix can't parse:
      # - Comment out Windows-specific "file://" line.
      # - Comment out ARMv7-specific "--only-binary" line.
      requirementsOriginalText = builtins.readFile "${src}/requirements.txt";
      requirementsText = builtins.replaceStrings
        [ "file://" "--only-binary" ]
        [ "#file://" "#--only-binary" ]
        requirementsOriginalText;
    in
    mach-nix.mkPython
      {
        requirements = requirementsText;
      };
in
stdenv.mkDerivation rec {
  pname = "esp-idf";
  version = rev;

  inherit src;

  # This is so that downstream derivations will have IDF_PATH set.
  setupHook = ./setup-hook.sh;

  propagatedBuildInputs = [
    # This is so that downstream derivations will run the Python setup hook and get PYTHONPATH set up correctly.
    pythonEnv.python
  ];

  installPhase = ''
    mkdir -p $out
    cp -r $src/* $out/

    # Link the Python environment in so that in shell derivations, the Python
    # setup hook will add the site-packages directory to PYTHONPATH.
    ln -s ${pythonEnv}/lib $out/
  '';
}
