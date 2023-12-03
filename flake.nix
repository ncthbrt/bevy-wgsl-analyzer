{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib stdenv;
        craneLib = crane.lib.${system};
        wgslFilter = path: _type: builtins.match ".*wgsl$" path != null;
        wgslOrCargo = path: type:
          (wgslFilter path type) || (craneLib.filterCargoSources path type);

        wgsl_analyzer = craneLib.buildPackage {
          src = lib.cleanSourceWith {
            src = craneLib.path ./.;
            filter = wgslOrCargo;
          };

          buildInputs =
            lib.optionals stdenv.isDarwin [
              pkgs.libiconv
            ];

          cargoExtraArgs = "-p wgsl_analyzer";
          pname = "wgsl_analyzer";
          version = "0.0.0";
        };
      in {
        packages.default = wgsl_analyzer;
        overlays.default = (self: super: { wgsl-analyzer = wgsl_analyzer; });
      });
}

