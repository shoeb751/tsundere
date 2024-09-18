{
  inputs = {
  };

  outputs = { self, nixpkgs }: {
    overlays = {
      default = import ./nix/default.nix;
    };
  };
}
