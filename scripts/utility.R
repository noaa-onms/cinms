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
  #info_modal_links_csv = "https://docs.google.com/spreadsheets/d/1yEuI7BT9fJEcGAFNPM0mCq16nFsbn0b-bNirYPU5W8c/gviz/tq?tqx=out:csv&sheet=ecosystems"){
  info_modal_links_csv = "https://docs.google.com/spreadsheets/d/1yEuI7BT9fJEcGAFNPM0mCq16nFsbn0b-bNirYPU5W8c/gviz/tq?tqx=out:csv&sheet=info_modal_links"){
  
  # rmd = "infauna.Rmd"
  # rmd = "key-human-activities.Rmd"
  modal_id <- basename(fs::path_ext_remove(rmd))
  
  #message(glue("modal_id: {modal_id}"))
  
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
    div(tagList(icons_html), style = "margin-top: 10px;margin-bottom: 10px; margin-right: 10px;"), div(
    ifelse(!is.na(row$tagline), row$tagline, ""), style = "margin: 10px; font-style: italic;"), style="display: flex"
    
    )
}

get_figure_info <- function (figure_id){
  # The purpose of this function is to generate the hyperlinks for the monitoring program and data 
  # associated with a figure and then to insert them into a gray bar above the figure in the modal window.
  
  #figure_id = "Figure App.E.10.22."
  
  info_csv = "https://docs.google.com/spreadsheets/d/1yEuI7BT9fJEcGAFNPM0mCq16nFsbn0b-bNirYPU5W8c/gviz/tq?tqx=out:csv&sheet=info_figure_links"
  
  d <- read_csv(info_csv)  %>% 
    filter(md_caption == figure_id)
  
  if (nrow(d) == 0){
    warning(paste("Need link in cinms_content:info_figure_links Google Sheet for", figure_id))
    return("")
  }
  
  html  <- NULL
  no_ws <- c("before","after","outside","after-begin","before-end")
  
  icons <- tribble(
    ~description_bkup   ,    ~css,            ~icon,         ~fld_url, ~fld_description,
    "Monitoring Program",  "left", "clipboard-list", "url_monitoring", "title_monitoring",
    "Data"              , "right", "database"      ,       "url_data", "title_data")
  
  for (i in 1:nrow(icons)){  # i=1
    
    h           <- icons[i,]
    url         <- d[h$fld_url]
    description <- d[h$fld_description]
    
    if(!is.na(url) & substr(url,0,4) == "http"){
      if (is.na(description)){
        description <- h$description_bkup
      } else {
        description <- substr(str_trim(description), 0, 45) 
      }   
      
      html <- tagList(
        html, 
        div(
          .noWS = no_ws,
          style = glue("text-align:{h$css}; display:table-cell;"),
          a(
            .noWS = no_ws,
            href = url, target = '_blank',
            icon(h$icon), description)))
    }
  }
  
  if (is.null(html))
    return("")
  
  tagList(
    div(
      .noWS = no_ws,
      style = "background:LightGrey; width:100%; display:table; font-size:120%; padding: 10px 10px 10px 10px; margin-bottom: 10px;",
      div(
        .noWS = no_ws,
        style = "display:table-row",
        html)))
}

render_caption <- function(figure_id){
  
  glue(
  "
  {md_caption(figure_id)}
  
  {md_caption(figure_id, get_details=T)}
  ")
  
}

render_figure <- function(figure_id, figure_img){
  
  # figure_id = "Figure App.F.12.2."
  # figure_img = "../img/cinms_cr/App.E.10.22.jpg"
  
  glue(
  "
  {get_figure_info(figure_id)}
  
  ![{md_caption(figure_id)}]({figure_img})
  
  {md_caption(figure_id, get_details=T)}
  ")
}