# output_test = paste(as.character(Sys.time()))
# write(output_test, file = "data/oceano/deletethis.txt", append = T)
devtools::install_github("marinebon/nms4r")
nms4r::generate_latest_SST("cinms","jplMURSST41mday", "sst", c("mean", "sd"))
