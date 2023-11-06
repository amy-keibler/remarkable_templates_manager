{
  description = "Amy's custom Remarkable templates manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        syncTemplates = pkgs.writeShellApplication {
          name = "sync_remarkable_templates";
          runtimeInputs = [ pkgs.rsync ];
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            mkdir --parents templates_backup
            rsync --archive --delete --quiet remarkable:/usr/share/remarkable/templates/ templates_backup
          '';
          };

        templatesList = pkgs.lib.trivial.importJSON templates_backup/templates.json;
      in
      {
        packages.templatesList = pkgs.writeText "test.json" (builtins.toJSON templatesList);

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            syncTemplates

            hexyl
            nixpkgs-fmt
          ];
        };
      });
}
