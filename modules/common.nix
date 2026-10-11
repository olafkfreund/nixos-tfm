# Options shared by the NixOS and Home Manager modules.
tfm:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.tfm;
in
{
  options.programs.tfm = {
    enable = lib.mkEnableOption "tfm, the mouse-first terminal file manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = tfm pkgs;
      defaultText = lib.literalExpression "nixos-tfm.packages.\${system}.tfm";
      description = "The tfm package.";
    };

    ffmpeg = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Point tfm at ffmpeg (TFM_FFMPEG) for video thumbnails.";
      };
      package = lib.mkPackageOption pkgs "ffmpeg-headless" { };
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        unzip
        zip
        p7zip
      ];
      defaultText = lib.literalExpression "with pkgs; [ unzip zip p7zip ]";
      description = "Helpers appended to tfm's PATH (archive handling).";
    };

    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = cfg.package.override {
        withFFmpeg = cfg.ffmpeg.enable;
        ffmpeg = cfg.ffmpeg.package;
        inherit (cfg) extraPackages;
      };
      description = "The tfm package with the options above applied.";
    };
  };
}
