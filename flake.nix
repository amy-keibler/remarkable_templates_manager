{
  description = "Amy's custom Remarkable templates manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, crane, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-analyzer" "rust-src" ];
        };

        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        src = craneLib.cleanCargoSource (craneLib.path ./template_translator);

        commonArgs = {
          inherit src;

          pname = "template_translator";
          version = "0.1.0";
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        template_translator = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
        });

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
          {
            name = "Cypher Character Abilities";
            filename = "cypher_character_abilities";
            categories = [ ];
            file = templates/cypher_character_abilities.svg;
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
        checks = {
          inherit template_translator;

          clippy = craneLib.cargoClippy (commonArgs // {
            inherit cargoArtifacts;
          });

          doc = craneLib.cargoDoc (commonArgs // {
            inherit cargoArtifacts;
          });

          fmt = craneLib.cargoFmt (commonArgs // {
            inherit src;
          });
};

        packages.template_translator = template_translator;

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
          inputsFrom = builtins.attrValues self.checks.${system};

          packages = with pkgs; [
            # Remarkable Tooling
            syncTemplates
            uploadTemplates

            # Rust
            rustToolchain
            cargo-edit
            cargo-expand
            cargo-insta
            cargo-msrv
            cargo-outdated

            # Python
            python3

            nixpkgs-fmt
          ];
        };
      });
}
