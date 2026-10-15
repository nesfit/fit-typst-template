{
  pkgs,
  ...
}:
pkgs.mkShell {
  packages = with pkgs; [
    (typst.withPackages (
      p: with p; [
        drafting
      ]
    ))
    tinymist
    hayagriva
    poppler-utils
  ];
}
