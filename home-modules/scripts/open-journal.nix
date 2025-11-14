{ config, lib, pkgs, ... }:

{
  home.file.".local/bin/open-journal.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      kitty nvim ~/Syncthing\ Computer/toto/journal.txt
    '';
    executable = true;
  };
}
