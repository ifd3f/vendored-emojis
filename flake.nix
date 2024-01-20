{
  description = "Vendored emoji collection";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      lib = pkgs.lib;
    in {
      overlays.default = final: prev: {
        akkoma-emoji = prev.akkoma-emoji
          // self.packages.${prev.system}.akkoma-emoji;
      };
    } // flake-utils.lib.eachDefaultSystem (system: {
      packages = pkgs.callPackage ./default.nix { inherit pkgs; };

      devShells.default = with pkgs;
        mkShell { buildInputs = [ python3 python3Packages.requests ]; };
    });
}
