{ pkgs, ... }:
{
  home.username = "tbusby";
  home.homeDirectory = "/home/tbusby";

  home.packages = [
    pkgs.todo-txt-cli
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
      nix-switch = "sudo nixos-rebuild switch --flake .#puter";
      nix-update = "nix flake update && sudo nixos-rebuild switch --flake .#puter";
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
    settings = {
      user = {
        name = "brubsby";
        email = "brubsbybrubsby@gmail.com";
      };
      init = {
        defaultBranch = "main";
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

  home.stateVersion = "25.05";
}
