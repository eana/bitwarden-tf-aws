{ pkgs }:
{
  settings.hooks = {
    prettier = {
      enable = true;
      files = "\\.json5?$";
      settings.write = false;
      settings.list-different = true;
    };
    check-yaml.enable = true;
    end-of-file-fixer.enable = true;
    check-merge-conflict = {
      enable = true;
      entry = "${pkgs.python312Packages.pre-commit-hooks}/bin/check-merge-conflict";
      types = [ "text" ];
    };
    deadnix.enable = true;
    statix.enable = true;
    tflint.enable = true;
    treefmt.enable = true;
    trivy = {
      enable = true;
      entry = "${pkgs.trivy}/bin/trivy config --exit-code 1 --tf-exclude-downloaded-modules .";
      pass_filenames = false;
      types = [ "file" ];
    };
  };
}
