library(rmarkdown)
library(here)
library(readr)
library(fs)
library(glue)
library(purrr)
library(dplyr)
here = here::here

# parameters
csv         <- here("svg/svg_links_cinms.csv")
redo_modals <- T

# skip modals that Ben has to process independently
skip_modals <- c(
  "key-climate-ocean.Rmd", 
  "deep-seafloor_key-climate-ocean.Rmd","kelp-forest_key-climate-ocean.Rmd","pelagic_key-climate-ocean.Rmd","rocky-shore_key-climate-ocean.Rmd","sandy-seafloor_key-climate-ocean","sandy-beach_key-climate-ocean.Rmd",
  
  # BB TODO:
  #   Quitting from lines 28-29 (barnacles.Rmd) 
  #   Error in sp_target %in% spp_targets : object 'sp_target' not found
  "barnacles.Rmd","mussels.Rmd","ochre-stars.Rmd",
  
  "forage-assemblage.Rmd", "forage-fish.Rmd", "forage-inverts.Rmd")

# read in links for svg
d <- read_csv(csv) %>% 
  mutate(dir = dirname(link))

d_modals <- d %>% 
  filter(dir != ".") %>% 
  group_by(link) %>% 
  summarize(n_habitats = n()) %>% 
  ungroup()

render_page <- function(rmd){
  render(rmd, html_document(
    theme = site_config()$output$html_document$theme, 
    self_contained=F, lib_dir = here("modals/modal_libs"), 
    mathjax = NULL))
}

render_modal <- function(rmd){
  rmds_theme_white <- c(
    "modals/barnacles.Rmd",
    "modals/mussels.Rmd")
  
  site_theme <- site_config()$output$html_document$theme
  rmd_theme  <- ifelse(rmd %in% rmds_theme_white, "cosmo", site_theme)
  
  render(rmd, html_document(
    theme = rmd_theme, 
    self_contained=F, lib_dir = here("modals/modal_libs"), 
    # toc=T, toc_depth=3, toc_float=T,
    mathjax = NULL))
  
}


# create/render modals by iterating over svg links in csv ----
for (i in 1:nrow(d_modals)){ # i=1
  # paths
  htm <- d_modals$link[i]
  rmd <- path_ext_set(htm, "Rmd")
  
  #if (htm == "modals/ca-sheephead.html") browser()
  
  # skip modals that Ben has to process independently
  if (basename(rmd) %in% skip_modals){
    message(glue("SKIPPING: {basename(rmd)} in skip_modals"))
    next()
  } 
  
  # create Rmd, if doesn't exist
  if (!file.exists(rmd)) file.create(rmd)
  
  # render Rmd to html, if Rmd newer or redoing
  if (file.exists(htm)){
    rmd_newer <- file_info(rmd)$modification_time > file_info(htm)$modification_time
  } else {
    rmd_newer <- T
  }
  
  # The following commented out if statement generates the modal windows only for Rmd files that
  # have been recently modified. The trouble with this code though is that we want the modal
  # windows to be regenerated if the glossary has been recently modified (which occurs on the 
  # cinms google spreadsheet), which wouldn't show up as a modification for the Rmd file. So, 
  # we actually need to run all modal windows to catch any changes that have been made to the 
  # glossary. This obviously makes render site slower to run - oh well
  
 # if (rmd_newer | redo_modals){
  #  message(glue("KNITTING: {basename(rmd)}"))
 #   render_modal(rmd)
  
#  }
  
  # let's replace the function render_modal(), used in the commented out if statement above,
  # with the function below which renders the html files from the rmd files, while
  # generating the tooltips for the html files
  rmd2html(rmd)
  
}

# render website, ie Rmds in root ----
#walk(list.files(".", "*\\.md$"), render_page)

rmarkdown::render_site()

#fs::file_touch("docs/.nojekyll")

# shortcuts w/out full render:
# file.copy("libs", "docs", recursive=T)
# file.copy("svg", "docs", recursive=T)
# file.copy("modals", "docs", recursive=T)

