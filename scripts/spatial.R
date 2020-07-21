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

# The following  function generates the mean SST for a national marine sanctuary for a given
# month. All parameters going into mean_SST have to be given as characters, with year being 
# four digits, month being two digits, and sanctuary being four digits (e.g "cinms" for Channel Islands 
# National Marine Sanctuary) 

#mean_SST <- function (sanctuary, year, month) {
ply2erddap <- function (sanctuary_code, erddap_id, erddap_fld, year, month, stats = c("mean", "sd")) {
  # sanctuary_code = "cinms"; erddap_id = "jplMURSST41mday"; erddap_fld = "sst"; year = 2020; month = 5; stats = c("mean", "sd")
  
  # check inputs
  stopifnot(all(is.numeric(year), is.numeric(month)))
  
  # Get the polygons for the sanctuary
  sanctuary_ply <- get_nms_polygons(sanctuary_code) %>% 
    st_union(sanctuary_ply) %>% 
    as_Spatial()
  
  # TODO: deal with wrapping around dateline
  # https://github.com/rstudio/leaflet/issues/225#issuecomment-347721709
  
  # The date range to be considered
  m_beg   <- ymd(glue("{year}-{month}-01"))
  m_end   <- beg + days(days_in_month(beg)) - days(1)
  m_dates <- c(m_beg, m_end)
    
  # set the x and y limits of the raster to be pulled based upon the sanctuary polygons
  bb <- st_bbox(sanctuary_ply)
  
  # pull the raster data
  nc <- griddap(
    info(erddap_id), 
    time = m_dates, 
    latitude = c(bb$ymin, bb$ymax), longitude = c(bb$xmax, bb$xmin), 
    fields = erddap_fld, fmt = 'nc')
  
  r <- raster(nc$summary$filename)

  stat <- stats[1]
  
  get_stat <- function(stat){
    fxn <- get(stat)
    raster::extract(
      r, sanctuary_ply_1, layer = 1, 
      method = "simple", fun = fxn)
  }
  
  sapply(stats, get_stat)
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

