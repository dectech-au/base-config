# /etc/nixos/hosts/G531GT-AL017T/flake-part.nix
#
# Accept an argument `hostName` (defaults to "placeholder").
# Pass it through `specialArgs`, then set networking.hostName
# in an inline module.  No generated file is needed.

{ inputs
, self
, hostName ? "placeholder"  # will be overridden from the CLI
, ...
}: {
  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations.G531GT-AL017T =
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      # Make hostName available to every module
      specialArgs = {
        inherit inputs hostName;
      };

      modules = [
        # Allow unfree packages
        { nixpkgs.config.allowUnfree = true; }

        # Inline module that sets the hostname
        ({ config, hostName, ... }: {
          networking.hostName = hostName;
        })

        # The rest of your configuration
        ./configuration.nix
        inputs.nixvim.nixosModules.nixvim
        inputs.remotemouse.nixosModules.remotemouse
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs      = true;
            useUserPackages    = true;
            backupFileExtension = "bak";
            users.dectec       = import ./home.nix;
            sharedModules      = [
              inputs.plasma-manager.homeManagerModules.plasma-manager
            ];
          };
        }
      ];
    };
}
