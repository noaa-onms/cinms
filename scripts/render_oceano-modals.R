library(infographiqR) # remotes::install_github("marinebon/infographiqR") 
library(onmsR) # remotes::install_github("noaa-onms/onmsR")

print('Rendering oceano_Rmds')
infographiqR::render_all_rmd(nms = "cinms", interactive_only = T)
print ('Finished rendering oceano_Rmds')
