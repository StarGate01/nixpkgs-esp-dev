# This version needs to be compatible with the version of ESP-IDF specified in `esp-idf/default.nix`.
{ version ? "2021r2-patch3"
, hash ? "sha256-WbJx0BT/ORW22xtDthCkXuoV/l1od9EsrooZHMmW7Tc="
, stdenv
, lib
, fetchurl
, makeWrapper
, buildFHSUserEnv
, autoPatchelfHook
, python27Packages
}:

let
  fhsEnv = buildFHSUserEnv {
    name = "esp32s3-toolchain-env";
    targetPkgs = pkgs: with pkgs; [ zlib ];
    runScript = "";
  };
in

assert stdenv.system == "x86_64-linux";

stdenv.mkDerivation rec {
  pname = "esp32s3-toolchain";
  inherit version;

  src = fetchurl {
    url = "https://github.com/espressif/crosstool-NG/releases/download/esp-${version}/xtensa-esp32s3-elf-gcc8_4_0-esp-${version}-linux-amd64.tar.gz";
    inherit hash;
  };

  buildInputs = [ 
    makeWrapper
    stdenv.cc.cc
    python27Packages.python
  ];

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  dontAutoPatchelf = true;

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    cp -r . $out
    for FILE in $(ls $out/bin); do
      FILE_PATH="$out/bin/$FILE"
      if [[ -x $FILE_PATH ]]; then
        autoPatchelf $FILE_PATH
        mv $FILE_PATH $FILE_PATH-unwrapped
        makeWrapper ${fhsEnv}/bin/esp32s3-toolchain-env $FILE_PATH --add-flags "$FILE_PATH-unwrapped"
      fi
    done
  '';

  meta = with lib; {
    description = "ESP32-S3 compiler toolchain";
    homepage = "https://docs.espressif.com/projects/esp-idf/en/stable/get-started/linux-setup.html";
    license = licenses.gpl3;
  };
}
