tfm:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.tfm;
  toml = pkgs.formats.toml { };
  configFile = toml.generate "tfm-config.toml" cfg.settings;
in
{
  imports = [ (import ./common.nix tfm) ];

  options.programs.tfm = {
    settings = lib.mkOption {
      inherit (toml) type;
      default = { };
      description = ''
        Seed for tfm's config.toml. Written only when the file is missing (or
        `forceSettings` is set), so changes made in tfm's Settings survive.
      '';
    };

    forceSettings = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Overwrite config.toml with `settings` on every activation.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];

    home.activation.tfmConfig = lib.mkIf (cfg.settings != { }) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        tfmConfig="''${XDG_CONFIG_HOME:-$HOME/.config}/tfm/config.toml"
        if [ ${lib.boolToString cfg.forceSettings} = true ] || [ ! -e "$tfmConfig" ]; then
          if [ -L "$tfmConfig" ]; then run rm -f "$tfmConfig"; fi
          run install -Dm644 ${configFile} "$tfmConfig"
        fi
      ''
    );
  };
}
