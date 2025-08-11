# hosts/G531GT-AL017T/flake-part.nix
{ inputs, self, ... } @ args:
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
        ../../sys-modules/sops.nix
        inputs.nixvim.nixosModules.nixvim
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
