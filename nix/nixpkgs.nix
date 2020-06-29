{}:

let
  nixpkgs-rev = "5272327b81ed355bbed5659b8d303cf2979b6953"; # 20.03
  nixpkgs-src = builtins.fetchTarball {
    url = "https://github.com/nixos/nixpkgs-channels/archive/${nixpkgs-rev}.tar.gz";
    sha256 = "0182ys095dfx02vl2a20j1hz92dx3mfgz2a6fhn31bqlp1wa8hlq";
  };

  overlay = nixpkgsSelf: nixpkgsSuper:
    let
      clash-src = nixpkgsSelf.fetchFromGitHub {
        owner = "clash-lang";
        repo = "clash-compiler";
        rev = "b17a60b0dc2cf51a6b96276c9c0bbfe4e11401c6";
        sha256 = "091ddfvxdq1whbaplmy0n1kshmcv7fbjxpl2zaal3b0nn0jp85q6";
      };
      clash-niv-sources = import "${clash-src}/nix/sources.nix";
    in {
    yosys = nixpkgsSelf.callPackage ./overlays/yosys.nix {};
    abc-verifier = nixpkgsSelf.callPackage ./overlays/abc-verifier.nix {};

    # Needed to build clash libraries using their nix
    gitignore = import clash-niv-sources.gitignore { inherit (nixpkgsSuper) lib; };

    haskellPackages = nixpkgsSuper.haskellPackages.override {
      overrides = self: super: {
        clash-ghc = import "${clash-src}/clash-ghc" { nixpkgs = nixpkgsSuper; };
        clash-lib = import "${clash-src}/clash-lib" { nixpkgs = nixpkgsSuper; };
        clash-prelude = import "${clash-src}/clash-prelude" { nixpkgs = nixpkgsSuper; };

        ghc-tcplugins-extra = self.callCabal2nix "ghc-tcplugins-extra" clash-niv-sources.ghc-tcplugins-extra {};
        ghc-typelits-extra = self.callCabal2nix "ghc-typelits-extra" clash-niv-sources.ghc-typelits-extra {};
        ghc-typelits-knownnat = self.callCabal2nix "ghc-typelits-knownnat" clash-niv-sources.ghc-typelits-knownnat {};
        ghc-typelits-natnormalise = self.callCabal2nix "ghc-typelits-natnormalise" clash-niv-sources.ghc-typelits-natnormalise {};
      };
    };
  };

in

import nixpkgs-src {
  overlays = [overlay];
}
