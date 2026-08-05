{ pkgs }:
{
  programs = {
    nixfmt = {
      enable = true;
      package = pkgs.nixfmt;
    };
    terraform = {
      enable = true;
      package = pkgs.opentofu;
    };
    yamlfmt.enable = true;
  };
  settings.formatter.terraform.includes = [
    "*.tf"
    "*.tfvars"
  ];
}
