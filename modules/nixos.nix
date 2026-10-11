tfm:
{ config, lib, ... }:

let
  cfg = config.programs.tfm;
in
{
  imports = [ (import ./common.nix tfm) ];

  config = lib.mkIf cfg.enable { environment.systemPackages = [ cfg.finalPackage ]; };
}
