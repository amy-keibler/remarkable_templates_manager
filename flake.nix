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

        uploadTemplates = pkgs.writeShellApplication {
          name = "upload_remarkable_templates";
          runtimeInputs = [ pkgs.rsync ];
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail
            rsync --archive --quiet result/ remarkable:/usr/share/remarkable/templates
            ssh remarkable 'systemctl restart xochitl'
          '';
        };

        remarkableTemplates = templates_backup/templates.json;
        customTemplates = [
          {
            name = "Burndown";
            filename = "burndown";
            categories = [ "Life/organize" ];
            file = templates/burndown.svg;
          }
        ];
        customTemplatesJson = pkgs.writeText "templates.json" (builtins.toJSON (map (template: builtins.removeAttrs template [ "file" ]) customTemplates));
        customTemplatesSvgs = map (template: template.file) customTemplates;

        pngFilenameFromSvg = svg: builtins.replaceStrings [".svg"] [".png"] (builtins.baseNameOf svg);

        convertToPngs = svgs: pkgs.stdenvNoCC.mkDerivation {
          name = "custom-template-pngs";

          dontUnpack = true;

          nativeBuildInputs = with pkgs; [ imagemagick ];

          buildPhase = builtins.concatStringsSep "\n" (builtins.map (svg: "convert ${svg} ${pngFilenameFromSvg svg}") svgs);

          installPhase = ''
            mkdir $out
            cp *.png $out/
          '';
        };

        customTemplatesPngs = convertToPngs customTemplatesSvgs;
      in
      rec
      {
        packages.customTemplates = pkgs.stdenvNoCC.mkDerivation {
          name = "custom-templates";
          src = ./.;

          nativeBuildInputs = with pkgs; [ python3 ];

          buildPhase = ''
            python ${./merge_templates.py} -- ${remarkableTemplates} ${customTemplatesJson} > templates.json
          '';

          installPhase = ''
            mkdir $out
            cp templates.json $out/templates.json
          ''
          + (builtins.concatStringsSep "\n" (builtins.map (svg: "cp ${svg} $out/${builtins.baseNameOf svg}") customTemplatesSvgs))
          + "\n"
          + "cp ${customTemplatesPngs}/*.png $out/";
        };

        packages.default = packages.customTemplates;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            syncTemplates
            uploadTemplates

            imagemagick
            python3

            nixpkgs-fmt
          ];
        };
      });
}
