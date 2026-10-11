# nixos-tfm

[tfm](https://github.com/clarkarch/tfm-tui), the mouse-first terminal file
manager, packaged for Nix with NixOS and Home Manager modules.

## Getting started

Try it without installing:

```sh
nix run github:olafkfreund/nixos-tfm
```

Add the flake input:

```nix
inputs.nixos-tfm = {
  url = "github:olafkfreund/nixos-tfm";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

NixOS:

```nix
{ inputs, ... }:
{
  imports = [ inputs.nixos-tfm.nixosModules.default ];
  programs.tfm.enable = true;
}
```

Home Manager:

```nix
{ inputs, ... }:
{
  imports = [ inputs.nixos-tfm.homeManagerModules.default ];
  programs.tfm = {
    enable = true;
    settings.ui."preview-enabled" = true;
  };
}
```

The package is also available as `packages.<system>.tfm` and through
`overlays.default` (`pkgs.tfm`).

## Options

All options live under `programs.tfm`.

| Option | Default | Description |
| --- | --- | --- |
| `enable` | `false` | Install tfm. |
| `package` | this flake's `tfm` | The base package. |
| `ffmpeg.enable` | `true` | Set `TFM_FFMPEG` so tfm can thumbnail video. |
| `ffmpeg.package` | `pkgs.ffmpeg-headless` | The ffmpeg to use. |
| `extraPackages` | `[ unzip zip p7zip ]` | Appended to tfm's `PATH`. |
| `finalPackage` | read-only | The package with the options above applied. |
| `settings` | `{ }` | Home Manager only: seed for `config.toml`. |
| `forceSettings` | `false` | Home Manager only: always overwrite. |

## Config seeding

tfm saves its own Settings screen to `~/.config/tfm/config.toml`, so the Home
Manager module does not own that file. When `settings` is non-empty, activation
writes it only if the file does not exist yet, and later changes made in tfm
survive rebuilds. Set `forceSettings = true` to have Nix overwrite it on every
activation instead.

## ffmpeg and helpers

The wrapper sets `TFM_FFMPEG` (as a default, so your environment still wins)
and appends `extraPackages` to `PATH` for archive handling. Set
`ffmpeg.enable = false` to drop ffmpeg from the closure.

## Updates

A daily workflow checks for a new upstream release, updates `sources.json`,
runs `nix flake check` and opens a pull request. CI checks x86_64 and aarch64.
To update by hand, run `scripts/update.sh`.

## How it is built

Upstream ships a single self-contained binary per architecture. This flake
fetches the release asset, sets the ELF interpreter with `patchelf`, and wraps
it. The binary is not stripped, since the app lives in an ELF section that
`strip` would remove.

## Licence

MIT, as is tfm itself.
