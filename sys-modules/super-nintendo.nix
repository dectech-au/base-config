home-manager.users.zozano = {
  home.packages = [
    (pkgs.retroarch.override {
      cores = with pkgs.libretro; [ bsnes snes9x ];
    })
  ];
};
