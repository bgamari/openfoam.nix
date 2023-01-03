{
  description = "Flake utils demo";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.nixpkgs.url = "github:bgamari/nixpkgs/wip/vtk-egg-info";

  inputs.openfoam = {
    url = "git+https://develop.openfoam.com/Development/openfoam";
    flake = false;
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        packages = rec {
          openfoam = pkgs.callPackage ./openfoam.nix {
            src = inputs.openfoam;
            mpi = pkgs.openmpi;
          };

          default = openfoam;
        };
      }
    );
}
