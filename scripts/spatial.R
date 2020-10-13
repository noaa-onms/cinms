library(here)
library(rgdal)
library(raster)
library(rerddap)
library(glue)
library(sf)
library(fs)
library(tidyverse)
library(lubridate)

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

# The following  function generates statistics for the SST for a national marine sanctuary for a given
# month. For the moment, when we say "statistics", we mean the average SST and standard deviation.  
# Parameters going into the function: 1) sanctuary_code: a string that describes a specific national marine sanctuary,
# ("cinms" for Channel Islands Marine Sanctuary), 2) erddap_id: the name of the satellite data set to be pulled 
# from erddap servers ("jplMURSST41mday" for Multi-scale Ultra-high Resolution SST Analysis), 3) erddap_fld: the parameter 
# to be pulled from the data set ("sst" for sea surface temperature), 4) year: in integer form, 5) month: in integer form,
# 6) stats: the statistics to be generated for the data set (c("mean", "sd"), to calculate mean and standard deviation).

ply2erddap <- function (sanctuary_code, erddap_id, erddap_fld, year, month, stats) {
  
  # check inputs
  stopifnot(all(is.numeric(year), is.numeric(month)))
  
  # Get the polygons for the sanctuary. The first version of this, which is commented out below, is written in tidyverse 
  # form, but doesn't work. The following error is produced when the tidyverse version is run: 
  # Error in UseMethod("st_geometry") : no applicable method for 'st_geometry' applied to an object of class "c('SpatialPolygonsDataFrame', 'SpatialPolygons', 'Spatial', 'SpatialVector')"
  
  # sanctuary_ply <- get_nms_polygons(sanctuary_code) %>% 
  # st_union(sanctuary_ply) %>% 
  # as_Spatial()
  
  # Get the polygons for the sanctuary, written in the more traditional fashion (and does work)
  sanctuary_ply <-   as_Spatial(st_union(get_nms_polygons(sanctuary_code)))

  # TODO: deal with wrapping around dateline
  # https://github.com/rstudio/leaflet/issues/225#issuecomment-347721709
  
  # The date range to be considered
  m_beg   <- ymd(glue("{year}-{month}-01"))
  m_end   <- m_beg + days(days_in_month(m_beg)) - days(1)
  m_dates <- c(m_beg, m_end)
    
  # set the x and y limits of the raster to be pulled based upon the sanctuary polygons
  bb <- st_bbox(sanctuary_ply)
  
  # pull the raster data
  nc <- griddap(
    info(erddap_id), 
    time = m_dates, 
    latitude = c(bb$ymin, bb$ymax), longitude = c(bb$xmax, bb$xmin), 
    fields = erddap_fld, fmt = 'nc')

  # Extract the raster from the data object. Confusingly, running the following line generates
  # the following error, but the code still runs and produces output:
  # Error in as.Date(time, origin = startDate) : object 'startDate' not found
  
  r <- raster(nc$summary$filename)

  # The following get_stat function extracts a statistical value (eg. mean or standard deviation) from the raster
  # cells remaining after being overlaid with the sanctuary polygons
  
  get_stat <- function(stat){
    fxn <- get(stat)
    raster::extract(
      r, sanctuary_ply, layer = 1, 
      method = "simple", fun = fxn)
  }
  
  # Let's run the function get_stat for every statistic asked for by the parameter value stats - this is the overall function output
  sapply(stats, get_stat)
}

# a quick function to generate a table of SST values for the Channel Island NMS from 2002-July 2020
generate_all_SST<- function(){
  date_SST <- seq(as.Date("2002-06-06"), by = "month", length.out = 218) 
  SST_file <- paste0(here("data/oceano/"),"avg-sst_cinms.csv")
  file.create(SST_file, showWarnings = TRUE)
  write("Year,Month,Average_SST,Standard_Deviation_SST", file = SST_file, append = TRUE)
  
  for (i in 1:length(date_SST)){
    year <- as.numeric(substr(date_SST[i], 1, 4))
    month <- as.numeric(substr(date_SST[i], 6, 7))
    print (date_SST[i])
    write_out = ply2erddap(sanctuary_code = "cinms", erddap_id = "jplMURSST41mday", erddap_fld = "sst", year = year, month = month, stats = c("mean", "sd"))
    write(paste0(year, "," , month, "," , round(write_out[1], 5), "," , round(write_out[2], 5)), file = SST_file, append = TRUE)
  }
  return(invisible())
}


generate_latest_SST<- function(){
  # this function generates the SST statistics for the latest month of available data. It (hopefully) is
  # run near the beginning of the month and generates the SST statistics for the month before that.
  
  # a function to generate first day of current month
  som <- function(x) {
    as.Date(format(x, "%Y-%m-01"))
  }

  # calculate the month and year of last month  
  last_month <- som(som(Sys.Date()) - 1)
  year <- as.numeric(substr(last_month, 1, 4))
  month <- as.numeric(substr(last_month, 6, 7))
  
  # The date range to be considered
  m_beg   <- ymd(glue("{year}-{month}-01"))
  m_end   <- m_beg + days(days_in_month(m_beg)) - days(1)
  m_dates <- c(m_beg, m_end)
  
  # write to this file
  SST_file <- paste0(here("data/oceano/"),"avg-sst_cinms.csv")

  # generate requested statistics using the ply2erddap function and then append the requested data to 
  # the csv file that has the data
  write_out = ply2erddap(sanctuary_code = "cinms", erddap_id = "jplMURSST41mday", erddap_fld = "sst", year = year, month = month, stats = c("mean", "sd"))
  write(paste0(year, "," , month, "," , round(write_out[1], 5), "," , round(write_out[2], 5)), file = SST_file, append = TRUE)
  return(invisible())
}



generate_all_chl<- function(){
  date_SST <- seq(as.Date("2002-06-06"), by = "month", length.out = 218) 
  SST_file <- paste0(here("data/oceano/"),"avg-sst_cinms.csv")
  file.create(SST_file, showWarnings = TRUE)
  write("Year,Month,Average_SST,Standard_Deviation_SST", file = SST_file, append = TRUE)
  
  for (i in 1:length(date_SST)){
    year <- as.numeric(substr(date_SST[i], 1, 4))
    month <- as.numeric(substr(date_SST[i], 6, 7))
    print (date_SST[i])
    write_out = ply2erddap(sanctuary_code = "cinms", erddap_id = "jplMURSST41mday", erddap_fld = "sst", year = year, month = month, stats = c("mean", "sd"))
    write(paste0(year, "," , month, "," , round(write_out[1], 5), "," , round(write_out[2], 5)), file = SST_file, append = TRUE)
  }
  return(invisible())
}
