{
  pkgs ?
    import (
      builtins.fetchTarball {
        name = "nixos-gcc13";
        url = "https://github.com/nixos/nixpkgs/archive/a9858885e197f984d92d7fe64e9fff6b2e488d40.tar.gz";
        sha256 = "0a55lp827bfx102czy0bp5d6pbp5lh6l0ysp3zs0m1gyniy2jck9";
      }
    )
    {},
}:
pkgs.callPackage ./package.nix {}
