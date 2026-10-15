{
  description = "updateself: cross-platform system and CLI tool updater";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      eachSystem = nixpkgs.lib.genAttrs systems;
    in {
      packages = eachSystem (system:
        let pkgs = import nixpkgs { inherit system; }; in {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "updateself";
            version = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile ./VERSION);
            src = ./.;
            nativeBuildInputs = [ pkgs.bash pkgs.makeWrapper ];
            dontBuild = true;
            installPhase = ''
              bash install.sh --system --prefix "$out" --destdir "$TMPDIR/stage"
              mkdir -p "$out"
              cp -R "$TMPDIR/stage/$out/"* "$out/"
              rm "$out/share/updateself/manifest"
              patchShebangs "$out/bin/updateself"
              wrapProgram "$out/bin/updateself" --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.gawk pkgs.findutils ]}
            '';
            meta = {
              description = "Update installed operating-system packages and CLI tools";
              homepage = "https://github.com/spaniakos/update-apt-system";
              license = pkgs.lib.licenses.gpl3Only;
              platforms = systems;
              mainProgram = "updateself";
            };
          };
        });
      checks = eachSystem (system: { package = self.packages.${system}.default; });
    };
}
