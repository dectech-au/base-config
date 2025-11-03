{ pkgs, lib, ... }:
{
  programs.nixvim = {
    enable = true;

    # Editor basics
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Performance + Wayland clipboard
    performance.byteCompileLua.enable = true;
    clipboard.providers.wl-copy.enable = true;

    # Theme
    colorschemes.gruvbox.enable = true;

    plugins = {
      # Treesitter
      treesitter = {
        enable = true;
        settings = {
          indent.enable = true;
          highlight.enable = true;
        };
      };

      # LSP
      lsp = {
        enable = true;
        nix.enable = true
        nix.autoArchive = true;
        servers = {
          nil_ls.enable = true;     # Nix
          lua_ls.enable = true;     # Lua
          bashls.enable = true;     # Bash
          html.enable = true;       # HTML
          cssls.enable = true;      # CSS
          ts_ls.enable = true;   # TS/JS
          pylsp.enable = true;      # Python
          dockerls.enable = true;   # Dockerfile
          # yamlls.enable = true;
          # jsonls.enable = true;
        };
        inlayHints = true;          # boolean on 25.05
        # NOTE: omit custom diagnostic keymaps here; they caused a Lua parse error.
      };

      # Completion + snippets
      cmp = {
        enable = true;
        autoEnableSources = true;
      };
      luasnip.enable = true;

      # Telescope + fzf
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
        };
        extensions."fzf-native".enable = true;
      };

      # UI / UX
      which-key.enable = true;
      lualine.enable = true;
      bufferline.enable = true;
      web-devicons.enable = true;
      notify.enable = true;

      # Git
      gitsigns.enable = true;
      fugitive.enable = true;

      # Editing QoL
      comment.enable = true;
      nvim-autopairs.enable = true;
      indent-blankline.enable = true;

      # File explorer
      neo-tree.enable = true;

      # Formatting on save (conservative)
      conform-nvim = {
        enable = true;
        settings.format_on_save = {
          lsp_fallback = true;
          timeout_ms = 1500;
        };
      };
    };

    # Options
    opts = {
      number = true;
      relativenumber = true;
      undofile = true;

      shiftwidth = 2;
      tabstop = 2;
      softtabstop = 2;
      expandtab = true;
      smartindent = true;
      autoindent = true;

      clipboard = "unnamedplus";
      ignorecase = true;
      smartcase = true;
      signcolumn = "yes:1";
      termguicolors = true;
      scrolloff = 5;
      splitright = true;
      splitbelow = true;
      guicursor = "n-v-c:blinkon0";
      updatetime = 300;
    };

    # Extra Lua
    extraConfigLua = ''
      vim.g.mapleader = " "
      vim.keymap.set("n", "<leader>w", "<cmd>write<CR>")
      vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>")
      vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>")
      vim.keymap.set("n", "n", "nzzzv")
      vim.keymap.set("n", "N", "Nzzzv")
      vim.keymap.set("n", "J", "mzJ`z")
      vim.o.updatetime = 300
    '';
  };
}
