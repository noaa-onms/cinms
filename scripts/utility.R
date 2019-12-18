
md_caption <- function(title = NULL, md = here::here("modals/_captions.md")){
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
      hdr = str_detect(ln, "^##") %>% na_if(F)) %>% 
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
  
  # prepend with title
  glue("**{title}**. {caption}")
}