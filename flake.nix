{
  description = "Lightning-fast and Powerful Code Editor written in Rust";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    crane,
  }: let
    flake-builder = system: let
      toml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
      inherit (toml.package) name version;
      pname = name;

      pkgs = import nixpkgs { inherit system; };

      buildInputs = with pkgs; [
          fontconfig
          glib
          gtk3
          zlib
          freetype
      ];

      commonArgs = {
        inherit pname;

        src = toString self;

        inherit buildInputs;

        dontUseCmakeConfigure = true;

        nativeBuildInputs = with pkgs; [
          clang
          cmake
          perl
          pkg-config
          gnumake
          mold
        ];
      };

      lapseDeps = crane.lib.${system}.buildDepsOnly commonArgs;

      lapse = crane.lib.${system}.buildPackage (commonArgs // {
        cargoArtifacts = lapseDeps;
      });

      lapseShell = pkgs.mkShell {
        inherit name buildInputs;

        nativeBuildInputs = with pkgs; [
          rnix-lsp
          cargo
          clang
          cmake
          pkg-config
          gnumake
          mold
          rustc
        ];

        shellHook = with pkgs; ''
          export LD_LIBRARY_PATH="$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}${
            lib.makeLibraryPath buildInputs
          }"
        '';
      };
    in {
      packages = { inherit lapse; default = lapse; };
      devShell = lapseShell;
    };
  in flake-utils.lib.eachDefaultSystem flake-builder;
}
