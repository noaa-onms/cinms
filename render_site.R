library(rmarkdown)
library(here)
library(readr)
library(fs)
library(glue)
library(purrr)
library(dplyr)
library(tools)

# delete this line

here = here::here

#load glossary generating functions
source(here("scripts/utility.R"))

# parameters
csv         <- here("svg/svg_links_cinms.csv")
redo_modals <- T

# skip modals that Ben has to process independently
skip_modals <- c(
  "key-climate-ocean.Rmd", "algal-groups.Rmd", "rocky-map.Rmd",
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

# The following section of code checks to see if there has been any change to
# the google spreadsheet cinms_content. If there has, we'll want to render all of the modal
# windows to account for changes to cinms_content

# The sheets of the google spreadsheet 
sheet_names <- c("info_modal_links", "info_figure_links", "glossary")

#The url of the google spreadsheet
cinms_content_url = "https://docs.google.com/spreadsheets/d/1yEuI7BT9fJEcGAFNPM0mCq16nFsbn0b-bNirYPU5W8c/gviz/tq?tqx=out:csv&sheet="

# Let's set a flag for whether the spreadsheet has changed
cinms_content_changed = FALSE

# Let's go through all three sheets
for (i in 1:3){
  
  # Save the new version of the sheet
  sheet_url = paste0(cinms_content_url, sheet_names[i])
  new_sheet <- read.csv(sheet_url)
  new_filename <- paste0(here("data/saved_cinms_content/new_"),sheet_names[i], ".csv")
  write.csv(new_sheet, file = new_filename)
  
  # Check to see if the new version of the sheet matches the saved version, if it doesn't 
  # change cinms_content_changed to TRUE 
  saved_filename <- paste0(here("data/saved_cinms_content/saved_"),sheet_names[i], ".csv")
  
  if (md5sum(new_filename) != md5sum(saved_filename)){
    cinms_content_changed = TRUE
    file.copy(new_filename, saved_filename, overwrite = TRUE)
  }
  file.remove (new_filename)
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
  
  # Render all modal windows if the associated google spreadsheet has changed or
  # if redo_modals is set to true. Re-render specific Rmd files that have been recently modified 
  
  if (rmd_newer | redo_modals | cinms_content_changed){
    message(glue("KNITTING: {basename(rmd)}"))
    #   render_modal(rmd)
    rmd2html(rmd)
  }
  
}

# render website, ie Rmds in root ----
#walk(list.files(".", "*\\.md$"), render_page)

rmarkdown::render_site()

#fs::file_touch("docs/.nojekyll")

# shortcuts w/out full render:
# file.copy("libs", "docs", recursive=T)
# file.copy("svg", "docs", recursive=T)
# file.copy("modals", "docs", recursive=T)
