library(nms4r)

print('Rendering oceano_Rmds')
nms4r::render_all_rmd(nms = "cinms", interactive_only = T)
#print('Rendering modals/kelp-forest_key-climate-ocean.Rmd')
#nms4r::generate_html_4_rmd(here::here("modals/kelp-forest_key-climate-ocean.Rmd"))
print ('Finished rendering oceano_Rmds')
