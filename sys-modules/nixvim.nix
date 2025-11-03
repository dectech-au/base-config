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

    # ---------------- Plugins ----------------
    plugins = {
      # Syntax and parsing
      treesitter = {
        enable = true;
        settings = {
          indent.enable = true;
          highlight.enable = true;
        };
      };

      # LSP + completion + snippets
      lsp = {
        enable = true;

        # Useful language servers. Safe on 25.05 without overlays.
        servers = {
          nil_ls.enable = true;     # Nix
          lua_ls.enable = true;     # Lua (Neovim config)
          bashls.enable = true;     # Bash/sh
          html.enable = true;       # HTML
          cssls.enable = true;      # CSS
          ts_ls.enable = true;      # TypeScript/JavaScript
          pylsp.enable = true;      # Python
          dockerls.enable = true;   # Dockerfile
          # Add more when needed:
          # yamlls.enable = true;
          # jsonls.enable = true;
        };

        # Turn on inline diagnostics, but keep it readable.
        keymaps = {
          diagnostic = {
            open_float = "gl";
            goto_next = "]d";
            goto_prev = "[d";
          };
        };
        inlayHints = { enable = true; };
      };

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          # Confirm with Enter, tab for navigation
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = ''
              function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                else
                  fallback()
                end
              end
            '';
            "<S-Tab>" = ''
              function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                  luasnip.jump(-1)
                else
                  fallback()
                end
              end
            '';
          };
        };
      };

      luasnip.enable = true;  # snippets backend for cmp

      # File finding and navigation
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = { action = "find_files"; desc = "Find files"; };
          "<leader>fg" = { action = "live_grep";  desc = "Live grep";  };
          "<leader>fb" = { action = "buffers";    desc = "Buffers";    };
          "<leader>fh" = { action = "help_tags";  desc = "Help tags";  };
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
      indent-blankline.enable = true;  # indent guides
      # Optional file tree (disable if you prefer netrw/mini.files):
      neo-tree = {
        enable = true;
        filesystem.followCurrentFile.enabled = true;
        window.mappings = { "<space>" = "none"; }; # avoid which-key clash
      };

      # Formatter on save (Conform). Keep conservative defaults.
      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            lsp_fallback = true;
            timeout_ms = 1500;
          };
        };
      };
    };

    # ---------------- Options ----------------
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
      updatetime = 300;   # snappier diagnostics update
    };

    # ---------------- Extra Lua ----------------
    extraConfigLua = ''
      -- Leader
      vim.g.mapleader = " "

      -- Quick save/quit
      vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Write" })
      vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>",  { desc = "Quit"  })

      -- Center after jumps
      vim.keymap.set("n", "n", "nzzzv")
      vim.keymap.set("n", "N", "Nzzzv")
      vim.keymap.set("n", "J", "mzJ`z")

      -- Neo-tree
      vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "File Explorer" })

      -- Diagnostics float on cursor
      vim.o.updatetime = 300
    '';
  };
}
