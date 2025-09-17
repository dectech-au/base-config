{ pkgs, ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      dockerfile-language-server = prev.nodePackages.dockerfile-language-server-nodejs;
    })
  ];
}
