# /etc/nixos/hosts/G531GT-AL017T/flake-part.nix
#
# ▸ You pass the real hostname from switch.sh:
#       nixos-rebuild … --argstr hostName "$name"
# ▸ We grab that arg from the flake-evaluation args set (`args`),
#   fall back to "placeholder" if it isn’t supplied,
#   and push it into `specialArgs` so every module can see it.
# ▸ An inline module sets `networking.hostName = hostName`.

{ inputs, self, ... } @ args:            # note the trailing @args
let
  hostName =
    if args ? hostName then args.hostName
    else "placeholder";
in
{
  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations.G531GT-AL017T =
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = {
        inherit inputs hostName;
        inherit (inputs) sops-nix;
      };

      modules = [
        # allow unfree
        { nixpkgs.config.allowUnfree = true; }

        # this sets the actual hostname
        ({ hostName, ... }: { networking.hostName = hostName; })

        ./configuration.nix
        inputs.nixvim.nixosModules.nixvim
       (import ../../sys-modules/remotemouse.nix { inherit pkgs; })
        (import ../../sys-modules/sops.nix { inherit (inputs) sops-nix; inherit pkgs; })
        inputs.home-manager.nixosModules.home-manager

        {
          home-manager = {
            useGlobalPkgs       = true;
            useUserPackages     = true;
            backupFileExtension = "bak";
            users.dectec        = import ./home.nix;
            sharedModules       = [
              inputs.plasma-manager.homeManagerModules.plasma-manager
            ];
          };
        }
      ];
    };
}
