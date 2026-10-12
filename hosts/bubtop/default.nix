{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../modules/nixos/common.nix
    ../../modules/nixos/desktop.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "bubtop";

  # Reachable from puter (and its gpu_watch) the moment it first boots.
  users.users.tbusby.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAWtZeGlquaU39lRO+zXkJVtmeY1y8G8ilSxQW9gsURo tbusby@puter"
  ];

  # Desktop tower: no fingerprint reader.
  services.fprintd.enable = lib.mkForce false;

  # RTX 4090. Track the default kernel rather than _latest so the NVIDIA module always has a matching build.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true; # Ada supports the open kernel module
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.nvidia-container-toolkit.enable = true; # GPU inside docker (enabled in common.nix)
  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    nvtopPackages.nvidia
    ntfs3g
  ];

  # Dual boot with Windows 11 on the same disk.
  time.hardwareClockInLocalTime = true; # Windows keeps the RTC in local time
  boot.supportedFilesystems = [ "ntfs" ];
  # NixOS has its own 1 GiB ESP; Windows' 99 MB ESP is left alone. A copy of \EFI\Microsoft\Boot on
  # this ESP makes systemd-boot list Windows automatically.
  boot.loader.systemd-boot.configurationLimit = 10;
}
