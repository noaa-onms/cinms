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

get_figure_info <- function (figure_id){
  # The purpose of this function is to generate the hyperlinks for the monitoring program and data 
  # associated with a figure and then to insert them into a gray bar above the figure in the modal window.
  
  #figure_id = "Figure App.E.10.22."
  
  # The data for this function are pulled from a google spreadsheet which is below
  input_file = "https://docs.google.com/spreadsheets/d/1yEuI7BT9fJEcGAFNPM0mCq16nFsbn0b-bNirYPU5W8c/gviz/tq?tqx=out:csv&sheet=info_figure_links"
  
  # Let's read in the relevant row of the spreadsheet, which is given by the figure name. If the figure name doesn't 
  # show up in the spreadsheet, stop the function and show an error.
  google_row <- read_csv(input_file)  %>% 
    filter(md_caption == figure_id)
  
  if (nrow(google_row) == 0) stop("Need link in cinms_content:info_figure_links Google Sheet!")
  
  # let's initialize a string variable that we'll use to keep track of the links going in the gray bar.
  output_string = ""
  
  # Here are parameters used in the function, set up as a data frame. The first row of the data frame contains the parameters
  # used when we are evaluating the monitoring program hyperlink. The second row contains the parameters used when we
  # are evaluating the data hyperlink.
  params <- data.frame ("default_url_description" = c("Monitoring Program", "Data"), "css" = c("left","right"), "icon" = c("fa-clipboard-list", "fa-database"))
  
  #The following for loop is here because we want to go through this process twice. The first time (i = 1), we're looking 
  #for the monitoring program hyperlink. The second time (i = 2), we're looking for the data hyperlink
  for (i in 1:2){  # i=1
    
    # The data in the spreadsheet is a mess so this function has to account for that. We only want to include records where there is an actual link, 
    # as opposed to notes, and that is what the following if statement looks for.
    the_url = google_row[2*i + 1]
    if(!is.na(the_url) & substr(the_url,0,4) == "http"){
      
      #If there isn't a name given for the url, let's give it a default
      url_description = google_row[2*i]
      if (is.na(url_description)){
        url_description = params$default_url_description[i]
      }
      #If a url name is given, let's make sure it isn't too long and also let's get rid of spaces
      else {
        url_description = substr(str_trim(url_description), 0, 39) 
      }   
      
      #let's glue  together html plus css stuff with the link and name of the link
      output_string = paste0(output_string, '<div style = "text-align:', params$css[i] ,'; display:table-cell;"><a href="', the_url,'" target="_blank"><i class="fas ', params$icon[i] ,'"></i> ', url_description, '</a></div>')
    }
  }
  
  # If there are no monitor program or data links for the figure, have the function return nothing. If output_string
  # still has nothing in it (which we set to nothing at the beginning of the function), then we know that there are no relevant links
  if (output_string == ""){
    return("")  
  }
  
  # If there is monitoring program and/or data links for the figure, 
  # the following is the complete css and html that gets outputted out by this function
  else {
    table_css = '<div style="background:LightGrey; width:100%; display:table; font-size:120%; padding: 10px 10px 10px 10px; margin-bottom: 10px;"><div style="display:table-row">'
    
    gray_bar = paste(table_css, output_string, "</div></div>")
    return(gray_bar)
    
  }
}

render_figure <- function(figure_id, figure_img){
  
  # figure_id = "Figure App.E.10.22."
  # figure_img = "../img/cinms_cr/App.E.10.22.jpg"

  info <- get_figure_info(figure_id)
  
  glue(
  "
  {get_figure_info(figure_id)}
  
  ![{md_caption(figure_id)}]({figure_img})
  
  {md_caption(figure_id, get_details=T)}`
  ")
}