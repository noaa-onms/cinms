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

# variables
sanctuary_code = "cinms"
erddap_id = "nesdisVHNSQchlaMonthly"
erddap_fld = "chlor_a"
year = 2020
month = 7

# the guts of ply2erddap
  
  # Get the polygons for the sanctuary, written in the more traditional fashion (and does work)
  sanctuary_ply <-   as_Spatial(st_union(get_nms_polygons(sanctuary_code)))

  # The date range to be considered
  m_beg   <- ymd(glue("{year}-{month}-01"))
  m_dates <- c(m_beg, m_beg)
  
  # set the x and y limits of the raster to be pulled based upon the sanctuary polygons
  bb <- st_bbox(sanctuary_ply)
  
  # pull the raster data
  
  m_dates_sst <- c(m_beg, ymd(glue("{year}-{month+1}-01")))
  
  m_beg_sst   <- ymd(glue("{year}-{month}-01"))
  m_end_sst   <- m_beg + days(days_in_month(m_beg)) - days(1)
  m_dates_sst <- c(m_beg_sst, m_end_sst)
  
  nc_sst <- griddap(
    info("jplMURSST41mday"), 
    time = m_dates_sst, 
    latitude = c(bb$ymin, bb$ymax), longitude = c(bb$xmax, bb$xmin), 
    fields = "sst", fmt = 'nc')
  
  nc <- griddap(
    info(erddap_id), 
    time = m_dates, 
    latitude = c(bb$ymin, bb$ymax), longitude = c(bb$xmax, bb$xmin), 
    fields = erddap_fld, fmt = 'nc')
  
  # Extract the raster from the data object. Something is funny about the filename This produces the following error for me:
  # [1] "vobjtovarid4: error #F: I could not find the requsted var (or dimvar) in the file!"
  # [1] "var (or dimvar) name: coord_ref"
  # [1] "file name: /Users/jai/Library/Caches/R/rerddap/e93f320f7d59040b4824d520e998c936.nc"
  
  
  r <- raster(nc_sst$summary$filename)
  
  r <- raster(nc$summary$filename, varname = erddap_fld)
  
  

  nc$summary$var[[erddap_fld]]$longname
  # but the raster exists!
  plot(raster(nc$summary$filename))
  
  get_stat <- function(stat){
    fxn <- get(stat)
    raster::extract(
      r, sanctuary_ply, layer = 1, 
      method = "simple", fun = fxn)
  }
  
  # error message:  Error in .readCells(x, cells, 1) : no data on disk or in memory 
  sapply(stats, get_stat)