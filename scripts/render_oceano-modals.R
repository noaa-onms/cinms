if (!require("librarian")){
  install.packages("librarian")
  library(librarian)
}
librarian::shelf(
  marinebon/infographiqR,
  noaa-onms/onmsR)
## devtools::load_all("../onmsR")

print('Rendering oceano_Rmds')
infographiqR::render_all_rmd(nms = "cinms", interactive_only = T)
print ('Finished rendering oceano_Rmds')
