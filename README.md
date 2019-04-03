# cinms
Channel Islands National Marine Sanctuary


## TODO

1. Wrap existing `r2d3(script="iq_scene.js", data=d)` into function like `info(svg="overview.svg", data=d, modal=F)` for `infographiq` R package


## SVG scenes

- [Latest CC Ai versions - Google Drive](https://drive.google.com/drive/u/1/folders/1nidp4cMJfrofJsEqQLNf7mGPF2swAW2P)

## Develop

Because of CORS, need local web server to debug:

```r
setwd(here::here("docs"))
servr::httw()
```

or

```bash
python -m SimpleHTTPServer 8000
```