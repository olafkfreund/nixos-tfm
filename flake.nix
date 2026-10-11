{
  description = "tfm (clarkarch/tfm-tui), the mouse-first terminal file manager, for NixOS and Home Manager";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      tfm = pkgs: pkgs.callPackage ./package.nix { };
    in
    {
      packages = forAllSystems (pkgs: rec {
        tfm = pkgs.callPackage ./package.nix { };
        default = tfm;
      });

      overlays.default = final: _prev: { tfm = tfm final; };

      nixosModules.default = import ./modules/nixos.nix tfm;
      homeManagerModules.default = import ./modules/home-manager.nix tfm;

      checks = forAllSystems (
        pkgs:
        let
          system = pkgs.stdenv.hostPlatform.system;
          pkg = self.packages.${system}.tfm;
          node = lib.nixosSystem {
            inherit system;
            modules = [
              self.nixosModules.default
              {
                programs.tfm = {
                  enable = true;
                  ffmpeg.enable = false;
                };
                boot.loader.grub.enable = false;
                fileSystems."/" = {
                  device = "none";
                  fsType = "tmpfs";
                };
                system.stateVersion = "26.05";
              }
            ];
          };
          final = node.config.programs.tfm.finalPackage;
        in
        {
          package = pkgs.runCommand "tfm-package-check" { } ''
            HOME=$TMPDIR ${pkg}/bin/tfm --version | grep -qF ${pkg.version}
            grep -q TFM_FFMPEG ${pkg}/bin/tfm
            touch $out
          '';
          module =
            assert lib.assertMsg (builtins.elem final node.config.environment.systemPackages)
              "tfm NixOS module: finalPackage is not in systemPackages";
            pkgs.runCommand "tfm-module-check" { } ''
              ! grep -q TFM_FFMPEG ${final}/bin/tfm
              touch $out
            '';
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
