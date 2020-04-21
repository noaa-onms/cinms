library(shiny)
library(readr)
library(dplyr)
library(htmltools)

md_caption <- function(title = NULL, md = here::here("modals/_captions.md"), get_details = F){
  #title = "Figure S.Hab.10.3."
  #title = "Figure App.F.12.17.new"
  #md_caption("Figure App.F.12.17.new")
  # title = "Figure App.C.4.4."
  
  #browser()
  
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(glue)
  
  stopifnot(file.exists(md))
  
  tbl <- tibble(
    # read lines of markdown in _captions.md
    ln = readLines(md) %>% str_trim()) %>%
    # detect header with title, set rest to NA
    mutate(
      is_hdr = str_detect(ln, glue("^## {title}")) %>% na_if(FALSE)) %>% 
    # fill down so capturing all starting with title header
    fill(is_hdr) %>% 
    # filter for title header down, removing previous lines
    filter(is_hdr) %>% 
    # remove title header
    slice(-1) %>% 
    # detect subsequent headers
    mutate(
      is_hdr = str_detect(ln, "^## ") %>% na_if(F)) %>% 
    # fill down
    fill(is_hdr) %>%
    mutate(
      is_hdr = replace_na(is_hdr, FALSE)) %>% 
    # filter for not header down, removing subsequent lines outside caption
    filter(!is_hdr) %>% 
    # details
    mutate(
      is_details = str_detect(ln, "^### Details") %>% na_if(F)) %>% 
    # fill down
    fill(is_details)
  
  simple_md <- tbl %>% 
    filter(is.na(is_details)) %>% 
    filter(ln != "") %>% 
    pull(ln) %>% 
    paste0(collapse = "\n") %>% 
    str_trim()
    
  details_md <- tbl %>%
    filter(is_details) %>% 
    filter(ln != "") %>% 
    pull(ln) %>% 
    paste0(collapse = "\n") %>% 
    str_replace(
      "### Details\n(.*)", 
      "<details>\n  <summary>Click for Details</summary>\n\\1</details>") %>% 
    str_trim()
  
  if (get_details == T){
    return(details_md)
  } else {
    return(glue("**{title}**. {simple_md}"))  
  }

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