{ pkgs, lib, ... }:
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
  ];

  home.sessionVariables = {
    EDITOR = "nano";
    GITHUB_TOKEN = "$(cat /run/user/$(id -u)/secrets/github_token)";
  };

  programs.bash.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      todo = "todo.sh";
      clip = "xclip -sel clipboard";
      nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#puter";
      nix-update = "nix flake update --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#puter";
      nix-update-local = "sudo nix flake update brubsby-nixpkgs-local --flake /etc/nixos && sudo nixos-rebuild switch --flake /etc/nixos#puter";
      home-switch = "home-manager switch -f /etc/nixos/home.nix";
      nix-config = "sudo $EDITOR /etc/nixos/configuration.nix";
      home-config = "sudo $EDITOR /etc/nixos/home.nix";
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

  # programs.starship = { ... } # Removed

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

  home.file.".todo/config".text =
    builtins.replaceStrings
      [
        "export TODO_DIR=\${HOME:-$USERPROFILE}"
        "# export TODOTXT_FINAL_FILTER='cat'"
        "#export TODO_ACTIONS_DIR=\" $HOME/.todo.actions.d\""
      ]
      [
        "export TODO_DIR=$HOME/Dropbox/todo"
        "export TODOTXT_FINAL_FILTER=\" $TODO_DIR/futureTask\""
        "export TODO_ACTIONS_DIR=\" $TODO_DIR/.todo.actions.d\""
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

  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;
}
