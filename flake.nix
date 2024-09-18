{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, fenix, rust-manifest }: {
    overlays = {
      default = import ./nix/default.nix;
    };
  };
}
