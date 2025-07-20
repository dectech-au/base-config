#/etc/nixos/sys-modules/emacs.nix
{ config, lib, pkgs, ... }:
{ 
  programs.emacs = {
    enable = true;
    package = pkgs.emacsPgtk;

  # Emacs build packages
  extraPackages = epkgs: with epkgs; [
    evil             # Vim-style modal editing
    which-key        # popup cheat-sheet for keybindings
    magit            # best Git UI on the planet
    use-package      # declarative package/config loader
    org              # Org-mode
    nix-mode         # syntax + indentation for .nix files

  # Core init file (loads before optional ~/.emacs.d files)
  extraConfig = ''
    ;; ==== UI cleanup ====
    (menu-bar-mode      -1)
    (tool-bar-mode      -1)
    (scroll-bar-mode    -1)
    (blink-cursor-mode  0)
    (setq inhibit-startup-screen t)
    (setq ring-bell-function 'ignore)

    ;; ==== Line numbers + column ====
    (global-display-line-numbers-mode 1)
    (column-number-mode 1)

    ;; ==== Evil (Vim) ====
    (setq evil-want-keybinding nil) ; avoid old compatibility layer
    (use-package evil
      :config
      (evil-mode 1))

    ;; ==== Which-key ====
    (use-package which-key
      :diminish
      :config
      (which-key-mode 1))

    ;; ==== Magit ====
    (use-package magit
      :commands (magit-status))

    ;; ==== Org ====
    (use-package org
      :hook ((org-mode . visual-line-mode))
      :config
      (setq org-hide-emphasis-markers t
            org-startup-indented t))

    ;; ==== Files end here ====
  '';
};

# Make emacs available in PATH for scripts
home.packages = [ pkgs.emacsPgtk ];
