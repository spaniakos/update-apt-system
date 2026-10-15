# Nix

Nix profiles and declarative systems are separate operations, on Linux or macOS.

```bash
updateself --only nix --dry-run
updateself --only nix --ask
```

Modern profiles use nix profile upgrade --all when available. Locked references
remain pinned. Recognised legacy profiles use the selected user's configured
channels and nix-env packages. Unsupported profiles are skipped.

## Declarative activation

```bash
updateself --only nix --base-install --nix-config home-manager --ask
updateself --only nix --base-install --nix-config nixos --nix-flake "$HOME/config" --ask
updateself --only nix --base-install --nix-config darwin --nix-flake "$HOME/config" --ask
```

Select the kind applicable to your host. home-manager, nixos-rebuild or
darwin-rebuild must already exist; system rebuild commands must be available to
the privileged command environment. Home Manager runs as the selected user.
--nix-flake is a local directory containing flake.nix.

## Explicit input changes

```bash
updateself --only nix --base-install --nix-config home-manager \
  --nix-flake "$HOME/config" --nix-update-inputs --ask
```

The extra flag updates that configuration's flake.lock before activation.
A random current directory is never implicitly selected. Failed/declined input
updates prevent dependent activation. Review your configuration diff yourself.

No channel switching, daemon self-upgrade or automatic generation deletion is
performed. --cleanup retains generations. This repository includes a pinned Nix
package definition verified in CI; Nixpkgs submission/cache hosting is future
work. See [[Packages and Releases|Packages-and-Releases]].
