#/etc/nixos/hosts/overlays.nix
{ inputs, ... }:
{
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
