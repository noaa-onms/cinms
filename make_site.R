library(tidyverse)
# devtools::install_github("marinebon/infographiq")
library(glue)
library(here)
library(infographiq)
here = here::here

setwd(here())
svg_overview <- "svg/cinms_overview.svg"

scenes <- read_csv(here("docs/svg-links.csv")) %>% 
  filter(svg == svg_overview) %>%
  mutate(
    svg  = glue("svg/cinms_{id}.svg"),
    html = glue("docs/{id}.html")) %>% 
  arrange(svg) %>% 
  bind_rows(
    tribble(
                  ~title,          ~svg, ~html,
      "CINMS Ecosystems",  svg_overview, "docs/index.html")) %>% 
  mutate(
    csv  = "svg-links.csv") %>% 
  select(title, csv, svg, html)
#View(scenes)
# afer rocky-shore

#scenes <- filter(scenes, svg == "svg/cinms_overview.svg")

make_scene <- function(i){ # i=1
  s <- scenes[i,]
  #browser()
  
  rmarkdown::render(
    input       = here("docs/_scene.Rmd"),
    params      = list(
      title = s$title,
      csv   = s$csv,
      svg   = s$svg),
    output_file = here(s$html))
}

# make_card("NAUTILUS")
# make_card("PACIFIC KINDNESS")
#ships$name[11] %>% walk(make_card)
walk(1:nrow(scenes), make_scene)
