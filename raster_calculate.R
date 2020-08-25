
library(tools)
library(here)


sheet_names <- c("info_modal_links", "info_figure_links", "glossary")
cinms_content_url = "https://docs.google.com/spreadsheets/d/1yEuI7BT9fJEcGAFNPM0mCq16nFsbn0b-bNirYPU5W8c/gviz/tq?tqx=out:csv&sheet="
cinms_content_changed = FALSE

for (i in 1:3){
  
  sheet_url = paste0(cinms_content_url, sheet_names[i])
  new_sheet <- read.csv(sheet_url)
  new_filename <- paste0(here("data/saved_cinms_content/new_"),sheet_names[i], ".csv")
  saved_filename <- paste0(here("data/saved_cinms_content/saved_"),sheet_names[i], ".csv")
  write.csv(new_sheet, file = new_filename)
  
  if (md5sum(new_filename) != md5sum(saved_filename)){
    cinms_content_changed = TRUE
    file.copy(new_filename, saved_filename, overwrite = TRUE)
  }
  file.remove (new_filename)
}

tempo