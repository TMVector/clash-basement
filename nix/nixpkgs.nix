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
        # From mp
        # rev = "da937e2da2cf5a0a33a8d00c1fcd9d7ac5cfc39a";
        # sha256 = "1njbydnwvbzw25lzs50sj1j5vj7lp3fx4zf7mb3is3fbm7y8yk3v";
        rev = "780db74e0a7245d2c76bbb4b8f83b70fc6f39ec9";
        sha256 = "1ph0c307g4z2yw9zh5wxvls9rv696fb0psvayx1p0f1ganygndfh";
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
