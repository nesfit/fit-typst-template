# Fonts

Fonts used by `../src/fit-thesis.typ` that Typst does not ship with. Typst
packages cannot contain fonts, so they are kept here for local builds only (not
part of the published package). The build script passes this directory to Typst
via `TYPST_FONT_PATHS`.

| File | Family | Used for | Source | License |
|---|---|---|---|---|
| `OpenSans-Bold.ttf` | Open Sans | title page | <https://github.com/googlefonts/opensans> | SIL Open Font License 1.1 (`OFL-OpenSans.txt`) |
| `NewCMMono10-*.otf` | New Computer Modern Mono | code, URLs | <https://ctan.org/pkg/newcomputermodern> | GUST Font License |

Body text and math use New Computer Modern, which is built into Typst.
