# This file is responsible for setting dev environment
# It defines binaries that will be provided and logic that will be run
# when 'nix develop .' will be executed
{ pkgs, ... }:
let
  inherit (pkgs) lib;

  displaySpacer = ''
    printf '%.0s-' {1..80}; printf '\n'
  '';

  displayRustToolsVersions = ''
    # cargo version
    if command -v cargo >/dev/null 2>&1; then
        CARGO_VER=$(cargo -V | grep -oP '(?<=cargo )\d+\.\d+\.\d+')
        echo "cargo: $CARGO_VER"
    fi

    # clippy version
    if command -v clippy-driver >/dev/null 2>&1; then
        CLIPPY_VER=$(clippy-driver -V | grep -oP '(?<=clippy )\d+\.\d+\.\d+')
        echo "clippy: $CLIPPY_VER"
    fi

    # rustc version
    if command -v rustc >/dev/null 2>&1; then
        RUSTC_VER=$(rustc -V | grep -oP '(?<=rustc )\d+\.\d+\.\d+')
        echo "rustc: $RUSTC_VER"
    fi

    # rustfmt version
    if command -v rustfmt >/dev/null 2>&1; then
        RUSTFMT_VER=$(rustfmt --version | grep -oP '(?<=rustfmt )\d+\.\d+\.\d+')
        echo "rustfmt: $RUSTFMT_VER"
    fi

    # rust-analyzer
    if command -v rust-analyzer >/dev/null 2>&1; then
        RUST_ANALYZER_VER=$(rust-analyzer -V | grep -oP '(?<=rust-analyzer )\d+\-\d+\-\d+')
        echo "rust-analyzer: $RUST_ANALYZER_VER"
    fi

  '';

  displayPythonToolsVersions = ''
    # python version
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_VER=$(python3 --version | grep -oP '(?<=Python )\d+\.\d+\.\d+')
        echo "Python: $PYTHON_VER"
    fi
  '';

  activateVenv = ''
    echo "Activating venv..."
    source .venv/bin/activate
  '';

  jsPackages = with pkgs; [
    nodejs_22
    pnpm
  ];

  pythonPackages = with pkgs; [
    python312
    uv
  ];

  rustPackages = with pkgs; [
    cargo
    clippy
    rustc
    rustfmt
    rust-analyzer
  ];

  cudaPackages = with pkgs.cudaPackages; [
    cudatoolkit
    cuda_nvrtc
    cuda_cupti
    cudnn
  ];

  ldLibs = pkgs.lib.makeLibraryPath (
    with pkgs;
    [
      stdenv.cc.cc
      zlib
    ]
    ++ cudaPackages
  );

  openglLibPath = "/run/opengl-driver/lib";
in
{
  default = pkgs.mkShell {
    # Nix packages provided in environment
    packages = jsPackages ++ pythonPackages ++ rustPackages ++ cudaPackages;

    # Environment variables
    env = {
      RUST_SRC_PATH = pkgs.rust.packages.stable.rustPlatform.rustLibSrc;
      NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
      NIX_LD_LIBRARY_PATH = ldLibs;
      LD_LIBRARY_PATH = "${openglLibPath}:${ldLibs}";
    };

    # Logic run on environment activation
    shellHook = ''
      ${displaySpacer}
      ${displayRustToolsVersions}
      ${displayPythonToolsVersions}
      ${displaySpacer}

      ${activateVenv}
    '';
  };

}
