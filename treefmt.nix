{ pkgs, ... }:
{
  projectRootFile = "flake.nix";
  programs.nixfmt.enable = true;
  programs.yamlfmt.enable = true;
  programs.prettier.enable = true;
  programs.shfmt.enable = true;
}
