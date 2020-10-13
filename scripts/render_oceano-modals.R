source(here::here("scripts/utility.R"))

print('Rendering oceano_Rmds')

# get the one working version for now 
# oceano_Rmds <- list.files(here("modals"), "^key-climate-ocean.Rmd$", full.names = T) 
# TODO: get other Rmds above to work:
#   oceano_Rmds <- list.files(here("modals"), "^[^_].*climate-ocean.Rmd$", full.names = T)

# create total list of files in directory
modal_dir<- paste0(here::here(),"/modals/")
modal_list<-list.files(path = modal_dir)

# find Rmd files that have _key-climate-ocean.Rmd in them
keep_modals<-grep("key-climate-ocean.Rmd",modal_list, ignore.case = TRUE)

# find Rmd files that are ONLY _key-climate-ocean.Rmd (which we don't want to render)
throw_out_modal<-grep("^_key-climate-ocean.Rmd$",modal_list, ignore.case = TRUE)

# create list of Rmds that we want to render and append full path to those file names
oceano_Rmds<-modal_list[keep_modals[!(keep_modals==throw_out_modal)]]
oceano_Rmds<-paste0(modal_dir,oceano_Rmds)

walk(oceano_Rmds, render)
# TODO: fix rmd2html so transfers all JavaScript libraries over from md to html
#   walk(oceano_Rmds, rmd2html)

print ('Finished rendering oceano_Rmds')
