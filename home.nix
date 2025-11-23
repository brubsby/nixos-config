let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{ pkgs, ... }: {
  home.username = "tbusby";
  home.homeDirectory = "/home/tbusby";

  home.packages = [
    pkgs.todo-txt-cli
  ];

  home.sessionVariables = {
     EDITOR = "nano";
  };

  home.shellAliases = {
    todo = "todo.sh";
    clip = "xclip -sel clipboard";
    nix-switch = "sudo nixos-rebuild switch";
    home-switch = "home-manager switch -f /etc/nixos/home.nix";
    nix-config = "sudo $EDITOR /etc/nixos/configuration.nix";
    home-config = "sudo $EDITOR /etc/nixos/home.nix";
  };

  programs.bash.enable = true;

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
    };
  };

  home.file.".todo/config".text = builtins.replaceStrings
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
