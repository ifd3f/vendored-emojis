{
  description = "Vendored emoji collection";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      lib = pkgs.lib;
      emojidata = with builtins; fromJSON (readFile ./sources.lock);
    in {
      overlays.default = final: prev: {
        akkoma-emoji = self.packages.${prev.system}.akkoma-emoji;
      };
    } // flake-utils.lib.eachDefaultSystem (system: {
      packages = {
        akkoma-emoji = lib.mapAttrs (k: v:
          let src = ././${v.pack_path};
          in pkgs.stdenvNoCC.mkDerivation {
            inherit src;

            pname = "akkoma-emoji-${k}";
            version = "unstable";

            PACK_MANIFEST = with builtins;
              with lib;
              toJSON {
                files = mapAttrs' (fname: match: {
                  name = head match;
                  value = fname;
                }) (filterAttrs (fname: matchResult: matchResult != null)
                  (mapAttrs (fname: ftype:
                    if ftype == "regular" then
                      match "(.*)\\..*" (baseNameOf fname)
                    else
                      null) (builtins.readDir src)));
              };

            installPhase = ''
              cp -Lr "$src" "$out"
              chmod 755 "$out"
              echo "$PACK_MANIFEST" > "$out/pack.json"
            '';

            phases = [ "installPhase" ];

            meta = {
              description = "${k} emoji pack";
              homepage = v.url;
            };
          }) emojidata;

        # Useful for testing a full build.
        all-akkoma-emoji = pkgs.linkFarm "all-akkoma-emoji"
          (lib.mapAttrsToList (name: path: { inherit name path; })
            self.packages.${system}.akkoma-emoji);
      };

      devShells.default = with pkgs;
        mkShell { buildInputs = [ python python3Packages.requests ]; };
    });
}
