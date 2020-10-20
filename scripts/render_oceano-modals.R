library(devtools)
devtools::install_github("marinebon/nms4r")

print('Rendering oceano_Rmds')
nms4r::generate_html_4_interactive_rmd("cinms")
print ('Finished rendering oceano_Rmds')
