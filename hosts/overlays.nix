#/etc/nixos/hosts/overlays.nix
{ inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      dockerfile-language-server = prev.nodePackages.dockerfile-language-server-nodejs;
    })
  ];


  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          firefox-addons = inputs.firefox-addons.packages.${system};
        })
      ];
    };
  };
}
