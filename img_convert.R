library(googledrive)
library(googlesheets4) # remotes::install_github("tidyverse/googlesheets4")
library(dplyr)
library(magick)
library(fs)
library(glue)
library(purrr)
library(stringr)

imgs_gid <- "10-66T_Uv3-3Rq5Hb-ljqsB72bpe3rT16dH4spPUuJXY"
dir_from <- "/Volumes/GoogleDrive/My Drive/projects/nms-web/cinms/Images"
dir_to   <- "~/github/cinms/img/cinms_cr"

get_path_from <- function(path){
  #message(path)
  
  #if (path == "State - Living Resources (S.LR.Q#.#)") browser()
  
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

img_convert <- function(path_from, path_to, width_in=6.5, dpi=150){
  width <- width_in * dpi
  
  if(is.na(path_from) | is.na(path_to)) return(NA)
  
  #browser()
  
  cmd <- glue('
  in="{path_from}"
  out_jpg="{path_to}"
  convert "$in" -trim -units pixelsperinch -density {dpi} -resize {width} "$out_jpg"')
  
  message(cmd)
  system(cmd)
  
  paths_01 <- glue("{path_ext_remove(path_to)}-{c(0,1)}.jpg")
  if (all(file.exists(paths_01))){
    file_copy(paths_01[2], path_to, overwrite = T)
    file_delete(paths_01)
  }
  #message(glue("{path_from}\t\n -> {path_to}\n", .trim = F))
}

# get "image_priorities" google sheet
imgs <- read_sheet(imgs_gid)

imgs <- imgs %>% 
  filter(
    !is.na(`infographic info`),
    !is.na(modal.Rmd)) %>% 
  mutate(
    path_from = map_chr(path, get_path_from),
    path_to   = map_chr(path_from, get_path_to))
# imgs %>% select(path, path_from, path_to) %>% View()

# convert images
imgs %>%
  filter(str_detect(path, "App.F.15.6.CalCOFI_diversity.tiff_parts")) %>% 
  select(path_from, path_to) %>% 
  pwalk(img_convert)

# manual
path_from="/Volumes/GoogleDrive/My Drive/projects/nms-web/cinms/Images_supplemental/App.F.12.19.hake.SoCAShelf.png"
path_to="/Users/bbest/github/cinms/img/cinms_cr/App.F.12.19.hake.SoCAShelf.jpg"
img_convert(path_from, path_to)
