[
  (self: super: {
    yosys = self.callPackage ./overlays/yosys.nix {};
    abc-verifier = self.callPackage ./overlays/abc-verifier.nix {};
  })
]
