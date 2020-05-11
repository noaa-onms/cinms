library(shiny)
library(readr)
library(dplyr)
library(htmltools)
library(glue)
library(dplyr)
library(tidyr)
library(stringr)

md_caption <- function(title, md = here::here("modals/_captions.md"), get_details = F){

  stopifnot(file.exists(md))
  
  tbl <- tibble(
    # read lines of markdown in _captions.md
    ln = readLines(md) %>% str_trim()) %>%
    # detect header with title, set rest to NA
    mutate(
      is_hdr = str_detect(
        ln, 
        glue('^## {str_replace_all(title, fixed("."), "\\\\.")}')) 
      %>% na_if(FALSE)) %>% 
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
    # replace links in markdown with html to open in new tab
    mutate(
      ln = str_replace_all(ln, "\\[(.*?)\\]\\((.*?)\\)", "<a href='\\2' target='_blank'>\\1</a>")) %>% 
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
    
  # Remove spaces around figure title.
  
  title <- str_trim(title)
  
  # If the last character of the figure title is a period, delete it. This will improve how the title looks when embedded into the text.
  
  if (substring(title, nchar(title))=="."){
      title<- substring(title,0,nchar(title)-1)
  }
      
  # Append figure title (like App.F.13.2) to the end of expanded figure caption and add link to condition report    
  
  expanded_caption = paste('<details>\n  <summary>Click for Details</summary>\n\\1 For more information, consult', title, 
    'in the [CINMS 2016 Condition Report](https://nmssanctuaries.blob.core.windows.net/sanctuaries-prod/media/docs/2016-condition-report-channel-islands-nms.pdf){target="_blank"}.</details>')
  
  details_md <- tbl %>%
    filter(is_details) %>% 
    filter(ln != "") %>% 
    pull(ln) %>% 
    paste0(collapse = "\n") %>% 
    str_replace("### Details\n(.*)", expanded_caption) %>% 
    str_trim()
  
  if (get_details == T){
    return(details_md)
  } else {
    return(simple_md) 
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
  rmd = knitr::current_input(),
  info_modal_links_csv = "https://docs.google.com/spreadsheets/d/1yEuI7BT9fJEcGAFNPM0mCq16nFsbn0b-bNirYPU5W8c/gviz/tq?tqx=out:csv&sheet=0"){
  
  # rmd = "abalone.Rmd"
  # rmd = "key-human-activities.Rmd"
  modal_id <- fs::path_ext_remove(rmd)
  
  # modal_id = "ochre-stars"
  row <- read_csv(info_modal_links_csv) %>% 
    filter(modal == modal_id)

  if (nrow(row) == 0) stop("Need link in cinms_content:info_modal_links Google Sheet!")
  
  icons_html = NULL
  if (!is.na(row$url_info)){
    icons_html = 
      a(icon("info-circle"), href=row$url_info, target='_blank')
  }
  if (!is.na(row$url_photo)){
    icons_html = tagList(
      icons_html, 
      a(icon("camera"), href=row$url_photo, target='_blank'))
  }
  
  div(
    ifelse(!is.na(row$tagline), row$tagline, ""), 
    style="font-style: italic",
    div(tagList(icons_html), align = "right"))
}