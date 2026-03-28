{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/nixos/common.nix
    # For a headless setup, we will need a hardware configuration.
    # For now, we'll import the same one to ensure it builds, but 
    # you should generate a new one for your actual headless machine.
    ../../hardware-configuration.nix
  ];

  networking.hostName = "headless";
  
  # Ensure graphical targets are disabled
  systemd.targets.graphical.enable = false;
  systemd.targets.multi-user.enable = true;
  systemd.defaultUnit = "multi-user.target";
}
