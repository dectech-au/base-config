#~/.dotfiles/flake.nix

{

  description = "DecTec default flake";



  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";



    flake-parts.url = "github:hercules-ci/flake-parts";

    #flake-parts.inputs.nixpkgs.follows = "nixpkgs";



    home-manager.url = "github:nix-community/home-manager/release-25.05";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";



    nixvim.url = "github:nix-community/nixvim";

    nixvim.inputs.nixpkgs.follows = "nixpkgs";




    aagl.url = "github:ezKEa/aagl-gtk-on-nix/release-25.05";


    aagl.inputs.nixpkgs.follows = "nixpkgs";




  };



  outputs = inputs@{ self, flake-parts, ... }:

    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [ "x86_64-linux" ];

      imports = [

        ./flake-parts/overlays.nix

        ./flake-parts/systems/enterprise-base/enterprise-base.nix

        ./flake-parts/systems/personal-tim/personal-tim.nix

      ];



      perSystem = { config, self', inputs', pkgs, system, ... }: {

        formatter = pkgs.nixpkgs-fmt;



        packages = {
          remotemouse = pkgs.callPackage ./remotemouse {
            libsForQt5 = pkgs.libsForQt5;
            glib = pkgs.glib;
            dbus = pkgs.dbus;
            zlib = pkgs.zlib;
            freetype = pkgs.freetype;
            fontconfig = pkgs.fontconfig;
            libxkbcommon = pkgs.libxkbcommon;
            libGL = pkgs.libGL;
            libGLU = pkgs.libGLU; # optional
            xorg = pkgs.xorg;
            alsa-lib = pkgs.alsa-lib;
            xdotool = pkgs.xdotool;
          };
        };



        devShells.default = pkgs.mkShell {

          packages = with pkgs; [

            git

            nixpkgs-fmt

            neovim

          ];

          shellHook = ''

            echo "Welcome to the mutha' fuckin' dev shell, you stupid bitch."

          '';

        };

      };

    };

}
