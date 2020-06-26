let
  nixpkgs = import ../nix/nixpkgs.nix {};

  haskellEnv = nixpkgs.haskell.packages.ghc865.ghcWithPackages (hs-pkgs: with hs-pkgs; [
    cabal-install

    clash-prelude
    clash-lib
    clash-ghc
    ghc-typelits-extra
    ghc-typelits-knownnat
    ghc-typelits-natnormalise

    constraints
    deepseq
    extra
    lens
    hedgehog
    HUnit
    QuickCheck
    tasty-hedgehog
    tasty-hunit
    vector
  ]);
in

nixpkgs.stdenv.mkDerivation {
  name = "env";
  phases = [];
  buildInputs = with nixpkgs; [
    # From https://symbiyosys.readthedocs.io/en/latest/quickstart.html
    yosys symbiyosys
    yices
    z3
    # super_prove # Not in nixpkgs?
    # avy # Broken
    boolector
    abc-verifier

    # Looking at https://github.com/thoughtpolice/clash-playground/blob/master/release.nix
    haskellEnv
    #verilog
    #cvc4 aiget picosat
  ];
}
