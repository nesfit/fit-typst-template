{
  pkgs,
  inputs,
  perSystem,
  ...
}:
let
  settings = {
    projectRootFile = "flake.nix";

    programs = {
      nixfmt.enable = true;
      texfmt.enable = true;
      typstyle = {
        enable = true;
      };
    };

    settings.formatter = {
      texfmt = {
        options = [
          "--nowrap"
        ];
      };
      typstyle = {
        options = [
          "--wrap-text=sentence"
        ];
      };
    };
  };

  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs settings;
in
treefmtEval.config.build.wrapper
