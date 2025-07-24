#/etc/nixos/sys-modules/onlyoffice.nix
{ config, lib, pkgs, ... }:
let
  onlyofficeEnv = pkgs.runFHSUserEnv {
    name = "onlyoffice-with-fonts";
    targetPkgs = pkgs: with pkgs; [
      onlyoffice-bin
      cantarell-fonts
      # add any other font packages you need here
    ];
    multiPkgs = true;
    runScript = "desktopeditors";  # or whatever the onlyoffice entrypoint is
  };
in {
	environment.systemPackages = with pkgs; [
		onlyoffice-bin
 		onlyofficeEnv
	];

	nixpkgs.config.allowUnfreePredicate = pkg:
		builtins.elem (lib.getName pkg)
		[
			"corefonts"
			"cantarell-fonts"
		];

	fonts = {
		
		enableDefaultPackages = true;
		enableGhostscriptFonts = true;

		packages = with pkgs; [
			corefonts
			vista-fonts
			liberation_ttf
			cantarell-fonts
			dejavu_fonts
			noto-fonts
			fira-code
			jetbrains-mono
		];
	};
}
