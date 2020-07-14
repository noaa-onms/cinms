library(here)
library(rgdal)
library(raster)
library(rerddap)
library(glue)
library(sf)
library(tidyverse)

# This function gets the polygons for a National Marine Sanctuary
get_nms_polygons <- function(nms){
  
  nms_shp <- here(glue("data/shp/{nms}_py.shp"))
  
  # download if needed
  if (!file.exists(nms_shp)){
    
    nms_url <- glue("https://sanctuaries.noaa.gov/library/imast/{nms}_py2.zip")
    nms_zip <- here(glue("data/{nms}.zip"))
    shp_dir <- here("data/shp")
    
    download.file(nms_url, nms_zip)
    unzip(nms_zip, exdir = shp_dir)
    file_delete(nms_zip)
  }
  # read and convert to standard geographic projection
  read_sf(nms_shp) %>%
    st_transform(4326)
}

# The following  function generates the mean SST for a national marine sanctuary for a given
# month. All parameters going into mean_SST have to be given as characters, with year being 
# four digits, month being two digits, and sanctuary being four digits (e.g "cinms" for Channel Islands 
# National Marine Sanctuary) 

mean_SST <- function (sanctuary, year, month) {
  
  # Get the polygons for the sanctuary.
  sanctuary_area <- get_nms_polygons(sanctuary)
  
  # The date range to be considered
  date_slice<-c(paste0(year,"-",month,'-01'), paste0(year,"-",month,'-28'))
  
  # set the x and y limits of the raster to be pulled based upon the sanctuary polygons
  bounds<- st_bbox(sanctuary_area)
  
  # pull the SST raster data
  raw_erddap <- griddap(info('jplMURSST41'), time = date_slice, latitude = c(bounds$ymin, bounds$ymax), longitude = c(bounds$xmax, bounds$xmin), fields = 'analysed_sst', fmt = 'csv')
  
  # manipulate the raster data so that it fits into a format that can be understood by the function rasterFromXYZ
  data_frame_erddap <- data.frame(longitude = round(raw_erddap$longitude, 2), latitude = round(raw_erddap$latitude, 2),sst = raw_erddap$analysed_sst)
  
  # generate the SST raster, overlay the sanctuary polygons over that, and extract the resulting SST values
  SST_map <- rasterFromXYZ(data_frame_erddap, res = c(0.01, 0.01), crs= "+init=epsg:4326")
  extracted_SST<- raster::extract(SST_map, sanctuary_area, method='simple')
  
  # take the average temperature and then return that as the function value
  all_temps <- unlist(extracted_SST)
  return(round(mean(all_temps),3))
}

# a quick function to generate a table of SST values for the Channel Island NMS from 2002-June 2020
generate_all_SST<- function(){
  date_SST <- data.frame(Date = seq(as.Date("2002-06-06"), by = "month", length.out = 216), Avg_SST = 0) # 216
  SST_file <- paste0(here("data/oceano/"),"avg-sst_cinms.csv")
  file.create(SST_file, showWarnings = TRUE)
  write("Date,Average_SST", file = SST_file, append = TRUE)
  
  for (i in 1:nrow(date_SST)){
    year <- substr(date_SST$Date[i], 1, 4)
    month <- substr(date_SST$Date[i], 6, 7)
    print (date_SST$Date[i])
    date_SST$Avg_SST[i] = mean_SST("cinms", year, month)
    write(paste0(date_SST$Date[i],",",date_SST$Avg_SST[i]), file = SST_file, append = TRUE)
  }
  return(invisible())
}

