source(here::here("scripts/utility.R"))

print('Rendering oceano_Rmds')

# get the one working version for now 
oceano_Rmds <- list.files(here("modals"), "^key-climate-ocean.Rmd$", full.names = T) 
# TODO: get other Rmds above to work:
#   oceano_Rmds <- list.files(here("modals"), "^[^_].*climate-ocean.Rmd$", full.names = T)

walk(oceano_Rmds, render)
# TODO: fix rmd2html so transfers all JavaScript libraries over from md to html
#   walk(oceano_Rmds, rmd2html)

print ('Finished rendering oceano_Rmds')
