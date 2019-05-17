# cinms
Channel Islands National Marine Sanctuary


## TODO

1. Wrap existing `r2d3(script="iq_scene.js", data=d)` into function like `info(svg="overview.svg", data=d, modal=F)` for `infographiq` R package


## SVG scenes

- [Latest CC Ai versions - Google Drive](https://drive.google.com/drive/u/1/folders/1nidp4cMJfrofJsEqQLNf7mGPF2swAW2P)

## Develop
### Modal Content Editing Workflow
1. edit .Rmd files in `./docs/modals/`
2. run `make_site.R`

NOTE: The `.html` files *can* be edited but by default `.html` files are overwritten by content knit from the `Rmd` files of the same name.
To use html directly set `redo_modals <- T`, but you will need to clear `.html` files manually with this setting.

### Testing
Because of CORS, need local web server to debug:

```r
setwd(here::here("docs"))
servr::httw()
```

or

```bash
python -m SimpleHTTPServer 8000
```
