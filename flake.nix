{
  description = "Bitwarden (vaultwarden) on AWS dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    dev-flake.url = "github:terlar/dev-flake";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [ inputs.dev-flake.flakeModule ];

      dev.name = "bitwarden-aws";

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import (
            if system == "x86_64-darwin" || system == "aarch64-darwin" then
              inputs.nixpkgs-darwin
            else
              inputs.nixpkgs
          ) { inherit system; };
          treefmt = import ./dev/treefmt.nix { inherit pkgs; };
          pre-commit = import ./dev/pre-commit.nix { inherit pkgs; };

          packages = {
            pre-commit = config.pre-commit.settings.package;
            pre-commit-install = pkgs.writeShellScriptBin "pre-commit-install" ''
              ${pkgs.pre-commit}/bin/pre-commit install
            '';
            tofu = pkgs.writeShellApplication {
              name = "tofu";
              runtimeInputs = [ pkgs.terraform-backend-git ];
              text = ''
                project="''${TF_PROJECT:-}"
                project_dir="''${TF_PROJECT_DIR:-}"

                if [ -z "$project" ]; then
                  case "$PWD" in
                    */example)
                      project="bitwarden-tf-aws"
                      project_dir="example"
                      ;;
                    *)
                      exec "${pkgs.opentofu}/bin/tofu" "$@"
                      ;;
                  esac
                fi

                state_repo="''${STATE_REPO_URL:-}"

                if [ -z "$state_repo" ]; then
                  echo "[WARNING] STATE_REPO_URL not set -- using LOCAL state" >&2
                  exec "${pkgs.opentofu}/bin/tofu" "$@"
                fi

                statefile="$project/$project_dir/terraform.tfstate"

                case "''${1:-}" in
                  init|plan|apply|destroy|import|state|output|refresh|validate)
                    exec terraform-backend-git git \
                      -r "$state_repo" \
                      -s "$statefile" \
                      -b master \
                      -d "$project_dir" \
                      terraform --tf "${pkgs.opentofu}/bin/tofu" "$@"
                    ;;
                  *)
                    exec "${pkgs.opentofu}/bin/tofu" "$@"
                    ;;
                esac
              '';
            };
          };

          devshells.default = {
            commands = [
              {
                name = "terraform";
                help = "OpenTofu with git-backed state (set STATE_REPO_URL for remote)";
                command = "${config.packages.tofu}/bin/tofu \"$@\"";
              }
            ];

            packages = with pkgs; [
              age
              awscli2
              cloudflared
              deadnix
              gnumake
              jq
              oath-toolkit
              opentofu
              (python3.withPackages (ps: [ ps.boto3 ]))
              ssm-session-manager-plugin
              sops
              sqlite-interactive
              statix
              terraform-backend-git
              trivy
            ];
          };
        };
    };

  nixConfig = {
    extra-substituters = "https://cache.nixos.org https://eana.cachix.org";
    extra-trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= eana.cachix.org-1:3sJHATrL9zjGFGZwAXpECSMR+Ql5k02GgdxfJyzHi84=";
  };
}
