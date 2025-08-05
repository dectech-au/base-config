{ config, lib, ... }:

let
  # read the serial, fall back to machine-id
  serial = lib.fileContents "/sys/class/dmi/id/product_serial" or (lib.fileContents "/etc/machine-id");
  # strip whitespace
  serial' = lib.removePrefix " " serial;          # crude but fine
  # last six characters
  len = builtins.stringLength serial';
  serial6 = builtins.substring (len - 6) 6 serial';
  name = "ASUS-G531GT-AL017T-${serial6}";
in {
  networking.hostName = name;
}
