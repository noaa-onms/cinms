library(shiny)
library(readr)
library(dplyr)
library(htmltools)

md_caption <- function(title = NULL, md = here::here("modals/_captions.md")){
  #title = "Figure S.Hab.10.3."
  #title = "Figure App.F.12.17.new"
  #md_caption("Figure App.F.12.17.new")
  
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(glue)
  
  stopifnot(file.exists(md))
  
  caption <- tibble(
    # read lines of markdown in _captions.md
    ln = readLines(md) %>% str_trim()) %>%
    # detect header with title, set rest to NA
    mutate(
      hdr = str_detect(ln, glue("^## {title}")) %>% na_if(FALSE)) %>% 
    # fill down so capturing all starting with title header
    fill(hdr) %>% 
    # filter for title header down, removing previous lines
    filter(hdr) %>% 
    # remove title header
    slice(-1) %>% 
    # detect subsequent headers
    mutate(
      hdr = str_detect(ln, "^## ") %>% na_if(F)) %>% 
    # fill down
    fill(hdr) %>%
    mutate(
      hdr = replace_na(hdr, FALSE)) %>% 
    # filter for not header down, removing subsequent lines outside caption
    filter(!hdr) %>% 
    # extract lines and collapse
    pull(ln) %>% paste0(collapse = "\n") %>% 
    # trim space and newlines
    str_trim()
  
  # handle details
  caption <- str_replace(
    caption,
    "### Details\n\n(.*)", 
    "<details><summary>\\1</summary></details>") 
  
  # prepend with title
  glue("**{title}**. {caption}")
}

add_icons <- function(info_url = NULL, photo_url = NULL){
  # info_url = "https://sanctuarysimon.org/2017/04/whale-entanglements-a-summary-as-of-april-2017/"
  # photo_url = "https://sanctuaries.noaa.gov/news/nov15/whale-disentanglement.html"
  
  if (!is.null(info_url)){
    inner = a(icon("info-circle"), href=info_url)
  } else {
    inner = NULL
  }
  
  if (!is.null(photo_url)){
    inner = tagList(inner, a(icon("camera"), href=photo_url))
  }
  
  div(inner, align = "right")
}

get_modal_info <- function(
  modal_id,
  info_modal_links_csv = "https://docs.google.com/spreadsheets/d/1yEuI7BT9fJEcGAFNPM0mCq16nFsbn0b-bNirYPU5W8c/gviz/tq?tqx=out:csv&sheet=0"){
  
  # modal_id = "ochre-stars"
  row <- read_csv(info_modal_links_csv) %>% 
    filter(modal == modal_id)
    
  div(
    tagList(
      a(icon("info-circle"), href=row$url_info), 
      a(icon("camera")     , href=row$url_photo)),
    align = "right")
}