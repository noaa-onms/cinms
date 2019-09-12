library(rmarkdown)
library(here)
library(readr)
library(fs)
library(purrr)

# parameters
csv         <- "svg/svg_links.csv"
redo_modals <- F

# read in links for svg
d <- read_csv(csv)

# create/render modals by iterating over svg links in csv ----
for (i in 1:nrow(d)){ # i=1
  # paths
  htm <- d$link[i]
  rmd <- path_ext_set(htm, "Rmd")
  
  # create Rmd, if doesn't exist
  if (!file.exists(rmd)) file.create(rmd)
  
  # render Rmd to html, if Rmd newer or redoing
  if (file.exists(htm)){
    rmd_newer <- file_info(rmd)$modification_time > file_info(htm)$modification_time
  } else {
    rmd_newer <- T
  }
  if (rmd_newer | redo_modals){
    render(rmd, html_document(
      theme = site_config()$output$html_document$theme, 
      self_contained=F, lib_dir = here("modals/modal_libs"), 
      mathjax = NULL))
  }
}

# render website, ie Rmds in root ----
walk(list.files(".", "*\\.md$"), render)
walk(
  list.files(".", "*\\.html$"), 
  function(x) file.copy(x, file.path("docs", x)))
render_site()

# file.copy("svg", "docs/svg", recursive=T)

