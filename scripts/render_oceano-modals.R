library(devtools)
devtools::install_github("marinebon/nms4r")

print('Rendering oceano_Rmds')
nms4r::render_all_rmd(nms = "cinms", interactive_only = T)
print ('Finished rendering oceano_Rmds')
