library(rmarkdown)

rmd2md <- function(rmd){
  
  md   <- fs::path_ext_set(rmd, "md")
  html <- fs::path_ext_set(rmd, "html")
  
  rmarkdown::render(
    rmd, output_file = html, 
    output_format    = "html_document", 
    output_options   = list(self_contained = F, keep_md = T),
    # output_yaml = here::here("modals/_md_output.yml"), 
    clean = T)
  rmarkdown::render(
    md , output_file = html, output_format = "html_document", clean = T)
}

# ---
#   always_allow_html: true
# ---

rmd <- here::here("modals/abalone.Rmd")
file.exists(rmd)
rmd2md(rmd)
