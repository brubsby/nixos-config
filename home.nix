{ pkgs, lib, inputs, ... }:
let
  repos = [
    "brubsby/nixpkgs"
    "oeis/oeisdata"
  ];
in
{
  home.username = "tbusby";
  home.homeDirectory = "/home/tbusby";
  home.packages = [
    pkgs.todo-txt-cli
    pkgs.neovim
    pkgs.snapshot
  ];

  home.sessionVariables = {
    EDITOR = "nano";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      todo = "todo.sh";
      clip = "xclip -sel clipboard";
      nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#puter";
      nix-update = "sudo nix flake update --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#puter";
      nix-update-local = "sudo nix flake update brubsby-nixpkgs-local --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#puter";
      home-switch = "home-manager switch --flake /etc/nixos#tbusby";
      nix-config = "$EDITOR /home/tbusby/Repos/nixos-config/configuration.nix";
      home-config = "$EDITOR /home/tbusby/Repos/nixos-config/home.nix";
      flake-config = "$EDITOR /home/tbusby/Repos/nixos-config/flake.nix";
      gs = "git status";
      gsv = "git status -v";
      gsvv = "git status -v -v";
      gl = "git log";
      gd = "git diff";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      beancount = "cd ~/Dropbox/Finances/Beancount && ./beancount_reference.sh";
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    initContent = ''
      # Powerlevel10k config
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      
      export GITHUB_TOKEN="$(cat /run/secrets/github_token)"
      export DISCORDO_TOKEN="$(cat /run/secrets/discord_token)"
      export HUCKLEBERRY_EMAIL="$(cat /run/secrets/huckleberry_email)"
      export HUCKLEBERRY_PASSWORD="$(cat /run/secrets/huckleberry_password)"
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:$LD_LIBRARY_PATH"
    '';
  };

  home.file.".p10k.zsh".source = ./p10k.zsh;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "basement" = {
        hostname = "bub-ucs240m5";
        user = "tbusby";
      };
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "brubsby";
        email = "brubsbybrubsby@gmail.com";
      };
      init = {
        defaultBranch = "main";
      };
      push = {
        autoSetupRemote = true;
      };
      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
      };
    };
  };

  programs.nixcord = {
    enable = true;
    discord.enable = true;
    vesktop.enable = true;
  };

  home.file.".todo/config".text =
    builtins.replaceStrings
      [
        "export TODO_DIR=\${HOME:-$USERPROFILE}"
        "# export TODOTXT_FINAL_FILTER='cat'"
        "#export TODO_ACTIONS_DIR=\"$HOME/.todo.actions.d\""
      ]
      [
        "export TODO_DIR=$HOME/Dropbox/todo"
        "export TODOTXT_FINAL_FILTER=\" $TODO_DIR/futureTask\""
        "export TODO_ACTIONS_DIR=\"$TODO_DIR/.todo.actions.d\""
      ]
      (builtins.readFile "${pkgs.todo-txt-cli}/etc/todo/config");

  home.activation.cloneRepos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.openssh}/bin:${pkgs.git-lfs}/bin:$PATH"
    mkdir -p $HOME/Repos
    ${builtins.concatStringsSep "\n" (
      map (
        repo:
        let
          name = builtins.elemAt (lib.splitString "/" repo) 1;
        in
        ''
          if [ ! -d "$HOME/Repos/${name}" ]; then
            $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/${repo}.git $HOME/Repos/${name}
          fi
        ''
      ) repos
    )}
  '';

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;
}
