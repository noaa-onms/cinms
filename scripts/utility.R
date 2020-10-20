if (!require(librarian)){
  install.packages("librarian")
  library(librarian)
}
shelf(
  dplyr, dygraphs, glue, here, htmltools, leafem, leaflet, marinebon/nms4r, purrr, readr, rerddap, rmarkdown, shiny, stringr, tidyr, xts)

# DEBUG
# remotes::install_github("marinebon/nms4r")
# devtools::load_all("~/github/nms4r")

addMouseCoordinates <- leafem::addMouseCoordinates
here                <- here::here
select              <- dplyr::select
addLegend           <- leaflet::addLegend

generate_html_4_interactive_rmd <- function (nms){
  # The purpose of generate_html is to create the html for rmd files with interactive figures.
  
  # the following mini-function where_is_head has two simple purposes. When fed in a html file, which has already been brought in
  # to R via readLines, the function will tell you the line number of the html file that contains "</html>" and
  # the total number of lines in the file
  where_is_head <-function(input_lines){
    i<-1  
    while (!(input_lines[i]=="</head>")){
      i <-i + 1
    }
    output_list <- list("total_lines" = length(input_lines), "head_line" = i)
    return(output_list)
  }
  
  # Let's figure out where we are. In my local environment, I am in the directory for 
  # the sanctuary. In a docker container though, I won't be. So the following section of 
  # code attempts to put us in the right directory if we aren't there already.
  location <- here::here()
  start_point <- nchar(location) - nchar(nms) +1
  if (!(substr(location, start_point, nchar(location)) == nms)){
    location <- paste(location, nms, sep = "/")
  }
  modal_dir<- paste0(location,"/modals/")
  modal_list<-list.files(path = modal_dir)
  
  # Now, let's generate a list of rmd files that need to be worked on. 
  
  # Step 1. find Rmd files that have _key-climate-ocean.Rmd in them
  keep_modals<-grep("key-climate-ocean.Rmd",modal_list, ignore.case = TRUE)
  
  # Step 2.  find the Rmd files that is ONLY _key-climate-ocean.Rmd (which we want to ignore)
  throw_out_modal<-grep("^_key-climate-ocean.Rmd$",modal_list, ignore.case = TRUE)
  
  # Step 3. create list of Rmds that we want to render and append full path to those file names
  oceano_Rmds<-modal_list[keep_modals[!(keep_modals==throw_out_modal)]]
  oceano_Rmds<-paste0(modal_dir,oceano_Rmds)

  # let's go through every rmd file to be worked on
  for (i in 1:length(oceano_Rmds)){
    # for a given rmd file, let's generate the html for it in two ways. Way 1 is via
    # rmd2html which gives us the glossary tooltip working right (but where the interactive
    # figures don't work). Way 2 is via render which gives us the interactive figures working 
    # right (but where the glossary tooltip doesn't work)
    target_rmd<- oceano_Rmds[i] #  "/Users/jai/Documents/cinms/modals/key-climate-ocean.Rmd"    
    rmd2html(target_rmd)
    rmarkdown::render(target_rmd, output_file = paste(modal_dir, "temp_file.html", sep ="/"))
    
    # We want both the interactive figures and the glossary tooltip working in the html. The way to do
    # that is to grab everything in the <head> section of the html produced by render and then 
    # to replace the <head> section of the html produced by rmd2html with that. The first step
    # here is to read in the two html files
    target_html <- gsub("Rmd", "html", target_rmd)
    target_lines  <- readLines(target_html)
    replacement_path <- paste0(modal_dir,"temp_file.html")
    replacement_lines <- readLines(replacement_path)

    # Next, let's figure out where the <head> section ends in each html file    
    target_location <- where_is_head(target_lines)
    replacement_location <-where_is_head(replacement_lines)
    
    # Now, let's replace the <head> section and save the new version of the html
    output_file = c(replacement_lines[1:replacement_location$head_line],target_lines[(target_location$head_line+1):target_location$total_lines])
    write(output_file, file = target_html)
    
    # let's delete the temp html file that we created
    file.remove(paste(modal_dir, "temp_file.html", sep ="/"))
  }
}

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
    div(tagList(icons_html), style = "margin-top: 10px;margin-bottom: 10px; margin-right: 10px; flex: 1;"), div(
    ifelse(!is.na(row$tagline), row$tagline, ""), style = "margin: 10px; font-style: italic; flex: 20; "), style="display: flex"
    
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

insert_tooltip<- function(text, glossary_term, span_css){
  # Draft version of code to render modal windows with tooltips. The overall idea is to generate a markdown file from a 
  # given modal rmd file. Within that markdown file, we then insert the javascript package tippy as well as inserting the
  # specific tippy tooltip. We then generate a html file for the modal window from the modified markdown file and then
  # delete the markdown file
  
  # The purpose of the following function is, for a provided section of text, to insert the required tooltip css around a 
  # provided glossary term. The function preserves the pattern of capitalization of the glossary term that already exists. 
  # The function requires three parameters: 1) text: the section of text where we are looking to add tooltips, 2) 
  # glossary_term: the glossary term that we are looking for, 3) span_css: the css tags to add before the glossary term
  
  
  
  # We start by splitting the text by the glossary term and then separately saving the glossary terms. This is done
  # so that we can preserve the pattern of capitalization of the glossary term
  split_text <- str_split(text, regex(glossary_term, ignore_case = TRUE))[[1]]
  save_glossary_terms <- c(str_extract_all(text, regex(glossary_term, ignore_case = TRUE))[[1]],"")
  
  # Let's go through every section of the split text and add the required css tags
  for (q in 1:length(split_text)){
    if (q>1){
      split_text[q] = paste0("</span>", split_text[q])
    }
    
    if (q<length(split_text)){
      split_text[q] = paste0(split_text[q], span_css)
    }
  }
  
  # put the split text and the glossary terms back together again and then return that as the output
  return (paste0(split_text, save_glossary_terms, collapse=""))
}

glossarize_md <- function(md, md_out = md){
  # The purpose of this function is to inject the html tags required for  glossary tooltip functionality into
  # a given md file 

  # read the markdown file 
  tx  <- readLines(md)
  
  # only go forward with the glossarizing if the file contains more than "data to be added soon"
  if (length(tx) > 12) {
  
    # load in the glossary that will be used to create the tooltips.  Reverse alphabetize the glossary, which will come in handy later
    glossary_csv = "https://docs.google.com/spreadsheets/d/1yEuI7BT9fJEcGAFNPM0mCq16nFsbn0b-bNirYPU5W8c/gviz/tq?tqx=out:csv&sheet=glossary"
    glossary <- read_csv(glossary_csv)
    glossary <- glossary[order(glossary$term, decreasing = TRUE),]
    
    # initialize the string variable that will hold the javascript tooltip
    script_tooltip = ""
    
    # go through each row of the glossary
    for (q in 1:nrow(glossary)) {
      
      # set a variable to zero that is used to keep track of whether a particular glossary word is in the modal window
      flag = 0
      
      # load in a specific glossary term
      search_term = glossary$term[q]
      
      # the css to be wrapped around any glossary word
      span_definition = paste0('<span aria-describedby="tooltip', q, '" tabindex="0" style="border-bottom: 1px dashed #000000; font-size:100%" id="tooltip', q, '">')
      
      # let's look to see if the glossary term is a subset of a longer glossary term (that is: "aragonite" and "aragonite saturation")
      # if it is a subset, we want to identify the longer term (so that we don't put the tooltip for the
      # shorter term with the longer term). Here is why the prior alphabetizing of the glossary matters
      glossary_match = glossary$term[startsWith (glossary$term, search_term)]
      
      if (length(glossary_match)>1){
        longer_term = glossary_match[1]
      }
      
      # let's go through every line of the markdown file looking for glossary words. We are skipping the first several
      # lines in order to avoid putting any tooltips in the modal window description
      for (i in 12:length(tx)) {
        
        # We want to avoid putting in tooltips in several situations that would cause the window to break.
        # 1. No tooltips on tabs (that is what the searching for "#" takes care of)
        # 2. No tooltips in the gray bar above the image (that is what the searching for the "</i>" and "</div> tags 
        # take care of)
        # 3. No tooltips on lines where there is a link for a data download
        if (substr(tx[i],1,1) != "#" && str_sub(tx[i],-4) != "</i>" && str_sub(tx[i],-5) != "</div>" && substr(tx[i], 1, 24) != "Download timeseries data"){
          
          # We also want to avoid inserting tooltips into the path of the image file, which is what the following
          # image_start is looking for. If a line does contain an image path, we want to separate that from the rest of
          # the line, do a glossary word replace on the image-less line, and then - later in this code - paste the image back on to the line 
          image_start = regexpr(pattern = "/img/cinms_cr", tx[i])[1] - 4
          
          if (image_start > 1) {
            line_content = substr(tx[i], 1, image_start)
            image_link = str_sub(tx[i], -(nchar(tx[i])-image_start))
          }
          else {
            line_content = tx[i]
          }
          
          # here is where we keep track of whether a glossary word shows up in the modal window - this will be used later 
          if (grepl(pattern = search_term, x = line_content, ignore.case = TRUE) ==TRUE){
            flag = 1
          }    
          
          # If the text contains a glossary term that is a shorter subset of another glossary term, we first
          # split the text by the longer glossary term and separately save the longer glossary terms (to preserve
          # the pattern of capitalization). We then run the split text through the tooltip function to add the required 
          # span tags around the glossary terms and then paste the split text back together
          if (length(glossary_match)>1){
            
            split_text_longer <- str_split(line_content, regex(longer_term, ignore_case = TRUE))[[1]]
            save_glossary_terms_longer <- c(str_extract_all(line_content, regex(longer_term, ignore_case = TRUE))[[1]],"")
            
            for (s in 1:length(split_text_longer)){
              split_text_longer[s] <- insert_tooltip(split_text_longer[s], search_term, span_definition)
            }
            line_content<- paste0(split_text_longer, save_glossary_terms_longer, collapse="")
          }
          
          else {
            # In the case that the glossary term is not a shorter subset, life is much easier. We just run the line of content
            # through the insert tooltip function
            line_content <- insert_tooltip(line_content, search_term, span_definition)
          }
          
          # if we separated the image path, let's paste it back on    
          if (image_start > 1) {
            tx[i] = paste0(line_content, image_link)
          }
          else {
            tx[i] = line_content
          }
        }
      }
      
      #if a glossary word was found in a modal window, let's add the javascript for that tooltip in
      if (flag == 1){
        script_tooltip = paste0(script_tooltip, '<script>tippy ("#tooltip', q, '",{content: "', glossary$definition[q], '"});</script>\r\n')
      }
    }
    
    # let's replace the markdown file with the modified version of the markdown file that contains all of the tooltip stuff 
    # (if any)
    writeLines(tx, con=md_out)
    
    # if any glossary words are found, let's add in the javascript needed to make this all go
    if (script_tooltip != ""){
      load_script=' <script src="https://unpkg.com/@popperjs/core@2"></script><script src="https://unpkg.com/tippy.js@6"></script>\r\n'
      write(   load_script, file=md_out, append=TRUE)
      write(script_tooltip, file=md_out, append=TRUE)
    }
  }
}

rmd2html <- function(rmd){
  # The purpose of rmd2html is to create the html for a rmd file - adding in the
  # glossary tooltip for glossary words in the rmd file
  md1  <- fs::path_ext_set(rmd, "md")
  md2  <- paste0(fs::path_ext_remove(rmd), ".glossarized.md")
  htm1 <- paste0(fs::path_ext_remove(rmd), ".glossarized.html")
  htm2 <- fs::path_ext_set(rmd, "html")
  
  # create the intermediary markdown file (with disposable html)
  render(
    rmd, output_file = htm1, 
    output_format    = "html_document", 
    output_options   = list(self_contained = F, keep_md = T))
  
  # glossarize
  glossarize_md(md2, md2)
  
  # create the final html file
  render(
    md2, output_file = htm2, 
    output_format    = "html_document", 
    output_options   = list(self_contained = F), clean = F)
  
  # final cleanup
  file.remove(htm1)  
  file.remove(md2)  
  file.remove(paste0(substring(md2,1,str_length(md2)-3),".utf8.md"))  
}