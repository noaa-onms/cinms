example_function <- function(modal_window){

  # set the path 
  modal_path = paste0(here::here("modals"),"/")
  
  # create the intermediary markdown file
  render(paste0(modal_path, modal_window, ".Rmd"), output_dir = modal_path, output_format = "md_document", clean = F)

}