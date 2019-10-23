library(googledrive)
library(googlesheets4) # remotes::install_github("tidyverse/googlesheets4")
library(dplyr)
library(magick)
library(fs)
library(glue)
library(purrr)

imgs_gid <- "10-66T_Uv3-3Rq5Hb-ljqsB72bpe3rT16dH4spPUuJXY"
dir_from <- "/Volumes/GoogleDrive/My Drive/projects/nms-web/cinms/Images"
dir_to   <- "~/github/cinms/img/cinms_cr"

# get "image_priorities" google sheet
imgs_sheet <- drive_get(id=imgs_gid)
imgs <- read_sheet(imgs_sheet)

get_path_from <- function(path){
  path_from <- file.path(dir_from, path)
  
  # check for other images
  paths <- list.files(
    dirname(path_from), 
    path_ext_remove(basename(path_from)), 
    full.names = T)
  
  if (length(paths) == 0 ) return(NA)
  
  # return one with biggest file size
  paths[which.max(file_info(paths)$size)]
}
# TODO: consolidate suffix repeats: *-0.* + *-1.* -> *.*

get_path_to <- function(path){
  if (is.na(path)) return(NA)
  
  glue("{dir_to}/{path_ext_remove(basename(path))}.jpg") %>% 
    path_real()
}

img_convert <- function(path_from, path_to, width=6.5, dpi=150){
  width    <- width_in * dpi
  
  if(is.na(path_from) | is.na(path_to)) return(NA)
  
  system(glue('
  in="{path_from}"
  out_jpg="{path_to}"
  convert "$in" -trim -units pixelsperinch -density {dpi} -resize {width} "$out_jpg"'))
}

imgs <- imgs %>% 
  filter(
    !is.na(`infographic info`),
    is.na(modal.Rmd)) %>% 
  mutate(
    path_from = map_chr(path, get_path_from),
    path_to   = map_chr(path_from, get_path_to))
#imgs %>% select(path, path_from, path_to) %>% View()

# convert images
imgs %>%
  select(path_from, path_to) %>% 
  pwalk(img_convert)
