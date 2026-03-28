{ config, pkgs, inputs, ... }:
let
  gemini-nightly = pkgs.writeShellScriptBin "gemini-nightly" ''
    export npm_config_yes=true
    exec ${pkgs.nodejs}/bin/npx @google/gemini-cli@nightly "$@"
  '';
  gemini-preview = pkgs.writeShellScriptBin "gemini-preview" ''
    export npm_config_yes=true
    exec ${pkgs.nodejs}/bin/npx @google/gemini-cli@preview "$@"
  '';
  qwen = pkgs.writeShellScriptBin "qwen" ''
    export npm_config_yes=true
    exec ${pkgs.nodejs}/bin/npx @qwen-code/qwen-code@latest "$@"
  '';
  yafu = pkgs.callPackage "${inputs.brubsby-nixpkgs-yafu}/pkgs/by-name/ya/yafu/package.nix" {
    enableAvx2 = true;
    enableBmi2 = true;
  };
  pfgwPkgs = import inputs.brubsby-nixpkgs-pfgw {
    inherit (pkgs) system;
    config = { allowUnfree = true; };
  };
  pfgw = pfgwPkgs.pfgw;
in
{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  time.timeZone = "America/New_York";
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

  console.useXkbConfig = true;

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  security.sudo.extraRules = [
    {
      users = [ "tbusby" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  virtualisation.docker.enable = true;

  users.users.tbusby = {
    isNormalUser = true;
    description = "tbusby";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    hashedPasswordFile = config.sops.secrets.tbusby_password.path;
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.system-features = [
    "nixos-test"
    "benchmark"
    "big-parallel"
    "kvm"
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
    system = "x86_64-linux";
  };

  documentation.man.generateCaches = true;

  environment.systemPackages = with pkgs; [
    wget
    leetcode-cli
    dropbox-cli
    xclip
    htop
    btop
    fastfetch
    bat
    jq
    ripgrep
    fd
    zip
    unzip
    nix-search-cli
    nix-update
    pkgs.home-manager
    sops
    age
    git
    gh
    hub
    gcc
    gdb
    gnumake
    ty
    python3
    uv
    nodejs
    typescript
    prettier
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer
    beancount
    beancount-language-server
    claude-code-bin
    gemini-cli-bin
    gemini-nightly
    gemini-preview
    opencode
    qwen
    pari
    maxima
    gap
    fricas
    ecm
    primesieve
    mprime
    yafu
    pfgw
    golly
    ghc
    scala
    guile
    perl
    ruby
    R
  ];

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
    "c240-wzp23290kkn" = {
      hostNames = [ "c240-wzp23290kkn" "c240-wzp23290kkn.lan" ];
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSWv0Y94G1vffCtT9ySkrX3XeEhLG6RZQ416vpteQodfCLEn9RkM8bAVP2P2Dk4AulEVgSzfp3MZB/SciuDS5jUW9Gtk/B6VrbBESR+TXmMSY0prjXuTTozRfhHRBiYqfowiIrnXx4N7HG0uyc/lVeMxcyIlw2xlho6p4HZYapbrYeF+PJENG3jUrTWvwI8tQrSoBchhebzOK/Yui4spfp7gAT2Exyem3J2JpHUhwi1NyFRz/oE7xNTgIU+W/QjK8yPvwAXp/foTMilAfIGwUJqDMxHPAYxBtS4d2XKnoSNDXthv8sIMAQLY9C3DqeedRChtidzFCK3a6BNxcFAXoRnGKHL+maDuXxNIWaboXlFUtuE+CQQ0Y23m3iUGCz9KLhYuwlLzDAKvMeq6hoPVo6LFpR3zESvloYE9XogZgUpMh7k43AG0CtKVBxOZ8VvHfJIAYvAjC6QpF7zgnvEPBQs1oFHi1Y1LhZmq/qIywTenXY/7o7nuM6X5nHOYlcyfU=";
    };
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
  ];

  system.stateVersion = "25.05";

  systemd.tmpfiles.rules = [
    "d /home/tbusby/.ssh 0700 tbusby users -"
  ];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
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
      pypi_token = {
        owner = "tbusby";
      };
      discord_token = {
        owner = "tbusby";
      };
      nasa_token = {
        owner = "tbusby";
      };
      huckleberry_email = {
        owner = "tbusby";
      };
      huckleberry_password = {
        owner = "tbusby";
      };
      "spotify_credentials/username" = {
        owner = "tbusby";
      };
      "spotify_credentials/auth_type" = {
        owner = "tbusby";
      };
      "spotify_credentials/auth_data" = {
        owner = "tbusby";
      };
      "leetcode_credentials/csrf_token" = {
        owner = "tbusby";
      };
      "leetcode_credentials/session_key" = {
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
