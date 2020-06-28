{}:

let
  nixpkgs-rev = "5272327b81ed355bbed5659b8d303cf2979b6953"; # 20.03
  nixpkgs-src = builtins.fetchTarball {
    url = "https://github.com/nixos/nixpkgs-channels/archive/${nixpkgs-rev}.tar.gz";
    sha256 = "0182ys095dfx02vl2a20j1hz92dx3mfgz2a6fhn31bqlp1wa8hlq";
  };

in

import nixpkgs-src {
  overlays = import ./overlays.nix;
}
