# ~/.dotfiles/z-nixos/modules/reliquary-archiver.nix
#
# NixOS module for reliquary-archiver (HSR relic export via packet capture)
# https://github.com/IceDynamix/reliquary-archiver
#
# Usage: in your configuration.nix (or wherever you compose modules):
#   programs.reliquary-archiver.enable = true;
#
# Update workflow when HSR patches:
#   1. Update `version` and `srcHash` to match the new reliquary-archiver release
#   2. Update `gamedataRev` and `gamedataHash` to a fresh commit from Dimbreath's repo
#   3. Set `cargoHash` to lib.fakeHash and rebuild — Nix will error with the correct hash
#   4. Paste the correct cargoHash and rebuild
#
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.reliquary-archiver;

  # ── Version pins ──────────────────────────────────────────────────────
  # Source
  version = "0.14.0";
  srcHash = lib.fakeHash; # replace after first build attempt

  # Game data (Dimbreath's datamined resources — changes each game patch)
  # Pin to a specific commit for reproducibility, or use "main" initially
  gamedataRev = "main";
  gamedataHash = lib.fakeHash; # replace after first build attempt

  # Cargo dependency hash (set to lib.fakeHash, rebuild, paste the real one)
  cargoHash' = lib.fakeHash;

  # ── Game data (pre-fetched for sandboxed build) ───────────────────────
  gamedata = pkgs.fetchgit {
    url = "https://gitlab.com/Dimbreath/turnbasedgamedata.git";
    rev = gamedataRev;
    hash = gamedataHash;
    sparseCheckout = [
      "ExcelOutput"
      "TextMap"
    ];
  };

  # ── Patch script for build.rs ─────────────────────────────────────────
  # build.rs downloads game data via HTTP at compile time.
  # Nix sandbox has no network, so we patch it to read from local files.
  buildRsPatch = ''
    # 1. Point BASE_RESOURCE_URL at the pre-fetched game data directory
    substituteInPlace build.rs \
      --replace-fail \
        'const BASE_RESOURCE_URL: &str = "https://gitlab.com/Dimbreath/turnbasedgamedata/-/raw/main";' \
        'const BASE_RESOURCE_URL: &str = "${gamedata}";'

    # 2. Replace the HTTP download function with a local file reader
    #    Original uses ureq::get(url).call().into_json()
    #    Replacement uses std::fs::read_to_string + ureq::serde_json::from_str
    ${pkgs.python3}/bin/python3 -c "
import re, sys
with open('build.rs', 'r') as f:
    content = f.read()

old_fn = re.compile(
    r'fn download_as_json<T: DeserializeOwned>\(url: &str\) -> T \{.*?\n\}',
    re.DOTALL
)

new_fn = '''fn download_as_json<T: DeserializeOwned>(path: &str) -> T {
    let content = std::fs::read_to_string(path)
        .unwrap_or_else(|e| panic!(\"Failed to read file {}: {}\", path, e));
    ureq::serde_json::from_str(&content)
        .unwrap_or_else(|e| panic!(\"Failed to parse json from {}: {}\", path, e))
}'''

result = old_fn.sub(new_fn, content, count=1)
if result == content:
    print('ERROR: Could not find download_as_json function to patch', file=sys.stderr)
    sys.exit(1)

with open('build.rs', 'w') as f:
    f.write(result)
print('Patched download_as_json to read from local files')
"
  '';

  # ── Package derivation ────────────────────────────────────────────────
  reliquary-archiver = pkgs.rustPlatform.buildRustPackage {
    pname = "reliquary-archiver";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "IceDynamix";
      repo = "reliquary-archiver";
      rev = "v${version}";
      hash = srcHash;
    };

    cargoHash = cargoHash';

    postPatch = buildRsPatch;

    nativeBuildInputs = with pkgs; [
      pkg-config
    ];

    buildInputs = with pkgs; [
      libpcap
      openssl
    ];

    doCheck = false;

    # Only build default Linux features (pcap + stream)
    # gui and pktmon are Windows-only
    buildNoDefaultFeatures = true;
    buildFeatures = [ "pcap" "stream" ];

    meta = {
      description = "HSR relic export from network packet capture";
      homepage = "https://github.com/IceDynamix/reliquary-archiver";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "reliquary-archiver";
    };
  };

in
{
  # ── Module interface ──────────────────────────────────────────────────
  options.programs.reliquary-archiver = {
    enable = lib.mkEnableOption "reliquary-archiver (HSR relic packet exporter)";
  };

  # ── Module implementation ─────────────────────────────────────────────
  config = lib.mkIf cfg.enable {

    # System-level: setcap wrapper so pcap can capture packets without sudo.
    # The binary at /run/wrappers/bin/reliquary-archiver gets CAP_NET_RAW.
    security.wrappers.reliquary-archiver = {
      source = "${reliquary-archiver}/bin/reliquary-archiver";
      capabilities = "cap_net_raw+ep";
      owner = "root";
      group = "root";
    };

    # Home-manager integration
    home-manager.users.zozano = {
      # Put the unwrapped binary on PATH too (for --help, etc.)
      home.packages = [ reliquary-archiver ];

      xdg.desktopEntries.reliquary-archiver = {
        name = "Reliquary Archiver";
        comment = "Export HSR relics via network packet capture";
        # Point at the setcap wrapper so it actually has capture permissions
        exec = "/run/wrappers/bin/reliquary-archiver --exit-after-capture";
        terminal = true;
        type = "Application";
        categories = [ "Game" "Utility" ];
      };
    };
  };
}
