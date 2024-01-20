{ lib, linkFarm, stdenvNoCC }:
let
  emojidata = with builtins;
    (mapAttrs (k:
      { pack_path, url, ... }: {
        inherit url;
        src = ././${pack_path};
      }) (fromJSON (readFile ./sources.lock))) // {
        codemascots.src = ./custom/codemascots;
        dinocursor.src = ./custom/dinocursor;
        minecraft = {
          url = "https://emoji.gg/emojis/minecraft";
          src = ./custom/minecraft;
        };
        misc.src = ./custom/misc;
        parrots = {
          url = "https://emoji.gg/pack/7302-party-parrots";
          src = ./custom/parrots;
        };
        verified = {
          url = "https://emoji.gg/pack/5595-verified";
          src = ./custom/verified;
        };
      };

  akkoma-emoji = lib.mapAttrs (k:
    { url ? null, src }:
    stdenvNoCC.mkDerivation {
      inherit src;

      pname = "emoji-${k}";
      version = "unstable";

      PACK_MANIFEST = with builtins;
        with lib;
        toJSON {
          files = mapAttrs' (fname: match: {
            name = head match;
            value = fname;
          }) (filterAttrs (fname: matchResult: matchResult != null) (mapAttrs
            (fname: ftype:
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
        homepage = url;
      };
    }) emojidata;
in {
  inherit akkoma-emoji;

  # Useful for testing a full build.
  all-akkoma-emoji = linkFarm "all-akkoma-emoji"
    (lib.mapAttrsToList (name: path: { inherit name path; }) akkoma-emoji);
}
