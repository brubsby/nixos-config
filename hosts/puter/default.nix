{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/desktop.nix
    ../../hardware-configuration.nix
  ];

  networking.hostName = "puter";
}
