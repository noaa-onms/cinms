library(tidyverse)
# devtools::install_github("marinebon/infographiq")
library(glue)
library(here)
library(infographiq)
library(rmarkdown)
here = here::here

# vars
csv          <- here("docs/svg-links.csv")
redo_modals  <-  T
redo_scenes  <-  F
svg_overview <- "svg/cinms_overview.svg"

# make scenes ----
# TODO: switch scenes to available svg

# setup scenes table
scenes <- read_csv(csv) %>% 
  # habitats besides overview
  filter(svg == svg_overview, !is.na(link_nonmodal)) %>%
  mutate(
    svg  = glue("svg/cinms_{id}.svg"),
    html = glue("docs/{id}.html")) %>% 
  arrange(svg) %>% 
  # overview
  bind_rows(
    tribble(
                  ~title,          ~svg, ~html,
      "CINMS Ecosystems",  svg_overview, "docs/index.html")) %>% 
  mutate(
    csv  = !!csv) %>% 
  select(title, csv, svg, html)
#View(scenes)

# temp filter
#scenes <- filter(scenes, svg == "svg/cinms_overview.svg")

# function to render scene
make_scene <- function(i, redo=redo_scenes){ # i=1
  s    <- scenes[i,]
  html <- here(s$html)
  
  if (!file.exists(html) | redo){
    render(
      input       = here("docs/_scene.Rmd"),
      params      = list(
        title = s$title,
        csv   = s$csv,
        svg   = s$svg),
      output_file = html)
  }
}
# walk scenes
#ships$name[11] %>% walk(make_card)
walk(1:nrow(scenes), make_scene)

# make modals ----
rmds <- list.files(here("docs/modals"), ".*\\.Rmd$", full.names = T)

# pinnipeds.Rmd: Could not fetch http://www3.mbari.org/bog/mbon/images/mb_seasonal_taxonomic_structure2.png
make_modal <- function(rmd, redo=redo_modals){
  html <- glue("{fs::path_ext_remove(rmd)}.html")
  if (!file.exists(html) | redo){
    render(rmd)
  }
}

walk(rmds, make_modal)


