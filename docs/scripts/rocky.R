library(tidyverse)
library(lubridate)
library(readxl)
library(here)
here = here::here
library(glue)
library(fs)
library(sf)
library(mapview)
library(RColorBrewer)

library(dygraphs) # devtools::install_github("rstudio/dygraphs")
library(xts)

#library(rerddap)
# cannot use rerddap b/c login presently required

raw_csv   <- "~/github/info-intertidal/MARINe_raw_4c1e_9218_7d13.csv"
sites_csv <- "~/github/info-intertidal/data/MARINe_sites.csv"
d_csv     <- "~/github/info-intertidal/data/sanctuary_species_percentcover.csv"

get_nms_ply <- function(nms){
  # get polygon for National Marine Sanctuary
  
  nms_shp <- glue("~/github/info-intertidal/data/shp/{nms}_py.shp")
  
  if (!file.exists(nms_shp)){
    # download if needed
    
    # https://sanctuaries.noaa.gov/library/imast_gis.html
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

plot_intertidal_nms <- function(d_csv, NMS, spp, sp_name){
  
  # read in csv with fields site, date, pct_cover
  d <- read_csv(d_csv) %>%
    filter(nms==NMS, sp==spp) %>%
    select(-nms, -sp) %>%
    spread(site, pct_cover) # View(d_sites)
  
  # line colors
  ln_colors <- c(colorRampPalette(brewer.pal(11, "Set3"))(ncol(d)-2), "black")
  
  # convert to xts time object
  x <- select(d, -date) %>%
    as.xts(order.by=d$date)
  
  # plot dygraph
  #browser()
  dygraph(x, main=glue("{sp_name} in {NMS}")) %>%
    dyOptions(
      connectSeparatedPoints = TRUE,
      colors = ln_colors) %>%
    dySeries(NMS, strokeWidth = 3) %>%
    dyHighlight(highlightSeriesOpts = list(strokeWidth = 2)) %>%
    dyRangeSelector()
}

map_nms_sites <- function(nms){
  # nms <- "cinms"
  NMS <- str_to_upper(nms)
  
  # get sites in nms
  sites_nms_shp <- glue("~/github/info-intertidal/data/shp/{NMS}_sites.shp")
  nms_ply <- get_nms_ply(nms)
  
  if (!file.exists(sites_nms_shp)){
    sites_nms_pts <- sites_pts %>%
      st_intersection(nms_ply)
    write_sf(sites_nms_pts, sites_nms_shp)
  }
  sites_nms_pts <- read_sf(sites_nms_shp)
  
  mapview(
    nms_ply, legend = TRUE, layer.name = "Sanctuary", zcol = "SANCTUARY") + 
    mapview(
      sites_nms_pts, legend = TRUE, layer.name = "Site",
      zcol = "site", col.regions = colorRampPalette(brewer.pal(11, "Set3")))
}

get_sites <- function(raw_csv, sites_csv){
  
  if (!file.exists(sites_csv)){
    raw     <- read_csv(raw_csv)
    
    sites_pts <- raw %>%
      rename(
        site = marine_site_name) %>%
      group_by(site) %>%
      summarize(
        lat = first(`latitude (degrees_north)`),
        lon = first(`longitude (degrees_east)`)) %>%
      st_as_sf(coords = c("lon", "lat"), crs = 4326, remove=F)
    
    sites_pts %>%
      st_set_geometry(NULL) %>%
      write_csv(sites_csv)
  }
  
  read_csv(sites_csv)
}
