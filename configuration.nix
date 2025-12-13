# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  ...
}:

let
  gemini = pkgs.writeShellScriptBin "gemini" ''
    export npm_config_yes=true
    exec ${pkgs.nodejs}/bin/npx @google/gemini-cli@nightly
  '';
  yafu = pkgs.callPackage "${inputs.brubsby-nixpkgs-local}/pkgs/by-name/ya/yafu/package.nix" {
    enableAvx2 = true;
    enableBmi2 = true;
  };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "puter"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  services.fprintd.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tbusby = {
    isNormalUser = true;
    description = "tbusby";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    hashedPasswordFile = config.sops.secrets.tbusby_password.path;
    packages = with pkgs; [
      kdePackages.kate
      #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.system-features = [
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
    #"gccarch-skylake"
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nixpkgs.hostPlatform = {
    #gcc.arch = "skylake";
    #gcc.tune = "skylake";
    system = "x86_64-linux";
  };

  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    # normie
    google-chrome
    dropbox-cli
    vlc
    obsidian
    # tui
    discordo
    # games
    # dwarf-fortress-packages.dwarf-fortress-full
    # linux
    xclip
    htop
    fastfetch
    # nix
    nix-search-cli
    pkgs.home-manager
    sops
    age
    # code
    git
    gcc
    gdb
    gnumake
    gh
    python3
    uv
    nodejs
    prettier
    # office
    beancount
    # ai
    gemini
    opencode
    # math
    pari
    ecm
    mprime
    yafu
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  programs.zsh.enable = true;
  users.users.tbusby.shell = pkgs.zsh;

  programs.ssh.knownHosts = {
    "github.com" = {
      hostNames = [ "github.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
    "gitlab.com" = {
      hostNames = [ "gitlab.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeGdHEDZAxv0";
    };
    "bub-ucs240m5" = {
      hostNames = [
        "bub-ucs240m5"
        "192.168.86.33"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHgHVy2geZWDIdDlqk8BWBFAh8jm/wZjKBUdND8ih/8Q";
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable nix-ld to run unpatched dynamic binaries (like Python wheels)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  systemd.tmpfiles.rules = [
    "d /home/tbusby/.ssh 0700 tbusby users -"
  ];

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    secrets = {
      tbusby_password = {
        neededForUsers = true;
      };
      wifi_psk = { };
      wifi_network = { };
      ssh_private_key = {
        owner = "tbusby";
        path = "/home/tbusby/.ssh/id_ed25519";
      };
      github_token = {
        owner = "tbusby";
      };
      discord_token = {
        owner = "tbusby";
      };
      huckleberry_email = {
        owner = "tbusby";
      };
      huckleberry_password = {
        owner = "tbusby";
      };
    };

    templates."nm-connection.nmconnection" = {
      content = ''
        [connection]
        id=${config.sops.placeholder.wifi_network}
        type=wifi

        [wifi]
        ssid=${config.sops.placeholder.wifi_network}

        [wifi-security]
        key-mgmt=wpa-psk
        psk=${config.sops.placeholder.wifi_psk}
      '';
      path = "/etc/NetworkManager/system-connections/sops-wifi.nmconnection";
      mode = "0600";
      restartUnits = [ "NetworkManager.service" ];
    };
  };

}
