if (!require("librarian")){
  install.packages("librarian")
  library(librarian)
}
librarian::shelf(
  glue, fs, here, lubridate, 
  noaa-onms/onmsR, # devtools::install_local("~/Github/noaa-onms/onmsR", force=T)
  raster, rerddap, rgdal, sf, tidyverse)

print('Starting SST...')
onmsR::calculate_statistics("cinms", "jplMURSST41mday", "sst", "statistics_sst_cinms.csv")
print('Starting Chlorophyll...')
onmsR::calculate_statistics("cinms", "nesdisVHNSQchlaMonthly", "chlor_a", "statistics_chl_cinms.csv")
print('Starting SST anomaly')
onmsR::calculate_SST_anomaly("cinms")
print ('Ending')
