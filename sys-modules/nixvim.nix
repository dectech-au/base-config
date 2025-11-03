{ pkgs, lib, ... }:
{
  # No overlays. Keep it simple.

  programs.nixvim = {
    enable = true;

    # Editor basics
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Sensible performance + clipboard for Wayland
    performance.byteCompileLua.enable = true;
    clipboard.providers.wl-copy.enable = true;

    # Theme
    colorschemes.gruvbox.enable = true;

    # --- Plugins ---
    plugins = {
      # Disable LSP entirely to avoid nixvim's atopile option default hitting a missing pkgs.atopile.
      # Re-enable later when your pin includes it.
      lsp.enable = false;

      # Useful, low-risk UI/UX plugins
      treesitter = {
        enable = true;
        settings.indent.enable = true;
      };

      notify.enable = true;
      lualine.enable = true;
      telescope.enable = true;
      web-devicons.enable = true;
      bufferline.enable = true;
      gitsigns.enable = true;
      comment.enable = true;
      nvim-autopairs.enable = true;
      indent-blankline.enable = true;

      # Git tooling inside Neovim
      fugitive.enable = true;

      # If you later re-enable LSP, this is how to keep dockerls off without overlays:
      # lsp = {
      #   enable = true;
      #   servers = {
      #     dockerls.enable = false;  # don't pull dockerfile-language-server
      #     # nil_ls.enable = true;
      #     # lua_ls.enable = true;
      #     # ts_ls.enable = true;
      #     # cssls.enable = true;
      #     # html.enable = true;
      #     # bashls.enable = true;
      #     # pylsp.enable = true;
      #   };
      # };
    };

    # --- Core options ---
    opts = {
      number = true;
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
    };

    # Example: later, when LSP is back, you can add keymaps or extra Lua here.
    # extraConfigLua = ''
    #   vim.keymap.set("n", "<leader>lg", ":LazyGit<CR>", { noremap = true, silent = true })
    # '';
  };
}
