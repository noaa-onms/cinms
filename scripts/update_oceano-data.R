library(here)
library(rgdal)
library(raster)
library(rerddap)
library(glue)
library(sf)
library(fs)
library(tidyverse)
library(lubridate)
library(nms4r)
# remotes::install_github("marinebon/nms4r")

print('Starting SST...')
nms4r::calculate_statistics("cinms", "jplMURSST41mday", "sst", "avg-sst_cinms.csv")
print('Starting Chlorophyll...')
nms4r::calculate_statistics("cinms", "nesdisVHNSQchlaMonthly", "chlor_a", "avg-chl_cinms.csv")
#nms4r::calculate_statistics("cinms", "nesdisVHNSQchlaMonthly", "chlor_a", "avg-chl_cinms.csv")
print ('Ending')

# [1] "Starting Chlorophyll..."
# In if (class(nc) == "try-error") { :
#     the condition has length > 1 and only the first element will be used
#   Error in nms4r::calculate_statistics("cinms", "nesdisVHNSQchlaMonthly",  : 
#   Error in erddap_id: this function only currently knows how to handle the datasets jplMURSST41mday and nesdisVHNSQchlaMonthly
