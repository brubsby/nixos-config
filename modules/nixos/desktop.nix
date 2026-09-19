{ config, pkgs, ... }:
{
  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "caps:escape";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.fprintd.enable = true;

  # Enable fingerprint auth for sudo via PAM
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.polkit-1.fprintAuth = true;

  # KDE askpass helper for graphical sudo prompts (supports fingerprint via PAM)
  environment.variables.SUDO_ASKPASS = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      vpl-gpu-rt
    ];
  };

  programs.firefox.enable = true;

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    hack-font
    jetbrains-mono
    fira-code
    source-code-pro
    # iosevka builds from source via nodejs_26, which has no binary cache
    # (a ~2h V8 compile); iosevka-bin is the upstream prebuilt release.
    iosevka-bin
    terminus_font_ttf
    gohufont
    cozette
    fixedsys-excelsior
    dina-font
    termsyn
  ];

  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  users.users.tbusby.packages = with pkgs; [
    kdePackages.kate
    kdePackages.kolourpaint
  ];

  environment.systemPackages = with pkgs; [
    google-chrome
    vlc
    zoom-us
    obs-studio
    obsidian
  ];
}
