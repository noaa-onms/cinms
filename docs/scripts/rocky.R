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

sanctuaries <- c("cinms", "mbnms", "ocnms")

dir_pfx   <- "~/github/info-intertidal"
#raw_csv   <- file.path(dir_pfx, "data/MARINe_raw_4c1e_9218_7d13.csv")
raw_csv   <- file.path(dir_pfx, "data/MARINe_raw_1c3b_9486_c22d.csv")
sites_csv <- file.path(dir_pfx, "data/MARINe_sites.csv")
d_csv     <- file.path(dir_pfx, "data/sanctuary_species_percentcover.csv")
raw_n_csv <- file.path(dir_pfx, "data/raw_summary_n.csv")
spp_csv   <- file.path(dir_pfx, "data/spp_targets.csv")
#sanctuaries_spp_csv <- file.path(dir_pfx, "data/nms_spp_targets.csv")
sanctuaries_spp_csv <- file.path(dir_pfx, "data/nms_spp.csv")
redo <- T

# https://www.eeb.ucsc.edu/pacificrockyintertidal/target/index.html
spp <- read_csv(spp_csv)
# TODO: MARINe_sscount_2c08_916b_1ec6.csv: MARINe seastarkat_count_totals
#  species_code: KATTUN 
# later: MARINe_sssize_971e_f4b1_6017.csv: MARINe seastarkat_size_count_totals 
#
# black-abalone
# black-oystercatcher
# inverts
# key-climate-ocean
# key-human-activities
# ochre-stars
# owl-limpets

get_nms_ply <- function(nms){
  # get polygon for National Marine Sanctuary
  
  nms_shp <- glue("{dir_pfx}/data/shp/{nms}_py.shp")
  
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
  # NMS = "OCNMS"; spp = "CHTBAL"; sp_name = "Acorn Barnacles"
  # NMS="OCNMS"; spp = c("BARNAC","CHTBAL"); sp_name = "Acorn Barnacles"
  # NMS="CINMS"; spp="CHTBAL"; sp_name="Acorn Barnacles"

  # read in csv with fields site, date, pct_cover
  d <- read_csv(d_csv) %>% # table(d$nms)
    filter(nms == NMS, sp %in% spp) %>%
    group_by(site, date) %>%
    summarize(pct_cover = sum(pct_cover)) %>% 
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
  # nms <- "cinms" # mbnms" # "ocnms"
  NMS <- str_to_upper(nms)
  
  # get sites in nms
  sites_nms_shp <- glue("~/github/info-intertidal/data/shp/{NMS}_sites.shp")
  nms_ply <- get_nms_ply(nms)
  
  if (!file.exists(sites_nms_shp)){
    if (!file.exists(sites_csv)) make_sites_csv(raw_csv, sites_csv)
    
    sites_pts <- read_csv(sites_csv) %>%
      st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = F)
    
    sites_nms_pts <- sites_pts %>%
      st_intersection(
        nms_ply %>% 
          st_buffer(0.01)) # 0.01 dd ≈ 1.11 km
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

make_sites_csv <- function(raw_csv, sites_csv){
  raw <- read_csv(raw_csv)
  
  sites_pts <- raw %>%
    rename(
      site = marine_site_name) %>%
    group_by(site) %>%
    summarize(
      lat = first(`latitude (degrees_north)`),
      lon = first(`longitude (degrees_east)`)) %>%
    st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = F)
  
  sites_pts %>%
    st_set_geometry(NULL) %>%
    write_csv(sites_csv)
}

make_nms_spp_pctcover <- function(sanctuaries, spp, raw_csv, d_csv, redo = F){
  
  raw <- read_csv(raw_csv)
  
  if (!file.exists(raw_n_csv) | redo){
    #head(raw, 1000) %>% View()
    #table(raw$lumping_code)
    #table(raw$target_assemblage)
    raw %>% 
      group_by(lumping_code, target_assemblage) %>% 
      summarize(n = n()) %>% 
      write_csv(raw_n_csv)
  }
  
  for (i in 1:length(sanctuaries)){ # i = 1
    
    # set sanctuary variables
    nms <- sanctuaries[i] # nms <- "cinms" # "mbnms" # "ocnms"
    NMS <- str_to_upper(nms)
    
    # get sites in nms
    sites_nms_shp <- file.path(dir_pfx, glue("data/shp/{NMS}_sites.shp"))
    if (!file.exists(sites_nms_shp)){
      nms_ply <- get_nms_ply(nms)
      sites_nms_pts <- sites_pts %>%
        st_intersection(
          nms_ply %>% 
            st_buffer(0.01))
      write_sf(sites_nms_pts, sites_nms_shp)
    }
    sites_nms_pts <- read_sf(sites_nms_shp)
    
    # plot map of sanctuary and sites
    # nms_ply <- get_nms_ply(nms)
    # m <- mapview(nms_ply) + sites_nms_pts
    # print(m)
    
    nms_spp_csv <- file.path(dir_pfx, glue("data/{NMS}_species.csv"))
    if (!file.exists(nms_spp_csv) | redo){
      nms_spp <- raw %>%
        rename(
          site    = marine_site_name,
          sp      = lumping_code,
          sp_name = lumping_name) %>% 
        filter(
          site %in% sites_nms_pts$site) %>% 
        group_by(sp, sp_name) %>% 
        summarize(n=n())
      
      stopifnot(length(unique(nms_spp$sp)) == nrow(nms_spp))
      
      write_csv(nms_spp, nms_spp_csv)
    }
    nms_spp <- read_csv(nms_spp_csv)
    
    # iterate over species
    for (j in 1:nrow(nms_spp)){ # j = 1
      
      # set species variables
      sp         <- nms_spp$sp[j]
      #sp_targets <- str_split(spp$sp_target[j], "\\|", simplify = T)[1,]
      sp_name    <- nms_spp$sp_name[j]
    
      # filter for nms-sp
      d_sites <- raw %>%
        rename(site = marine_site_name) %>%
        filter(
          site %in% sites_nms_pts$site,
          #target_assemblage %in% sp_targets,
          lumping_code == sp)
      
      # next sp if empty
      if (nrow(d_sites) == 0) next()
      
      # average across plots for each site-species-date
      d_sites <- d_sites %>%
        mutate(
          date = ymd(`time (UTC)`)) %>%
        group_by(site, date) %>%
        summarize(
          pct_cover = mean(percent_cover)) # View(d_sites)
      
      # average across sites to nms-year
      d_nms <- d_sites %>%
        mutate(
          date = date(glue("{year(date)}-06-15"))) %>%
        group_by(date) %>%
        summarize(
          pct_cover = mean(pct_cover)) %>%
        ungroup() %>%
        mutate(
          site = NMS) # View(d_nms)
      
      # combine sites and sanctuary annual average
      d <- bind_rows(
        d_sites,
        d_nms) %>%
        mutate(
          nms = NMS,
          sp  = sp) # View(d)
      
      # write data to csv
      if (i == 1 & j == 1){
        write_csv(d, d_csv)
      } else {
        write_csv(d, d_csv, append=T)
      }
      
      # generate timeseries plot
      #p <- plot_intertidal_nms(d_csv, NMS, sp_name)
      #print(p)
    }
  }
}

#ocnms <- get_nms_ply("ocnms")
#map_nms_sites("ocnms")

if (!file.exists(d_csv) | redo){
  # NOTE: remake d_csv if adding a sanctuary or species
  make_nms_spp_pctcover(sanctuaries, spp, raw_csv, d_csv, redo = redo)
}

if (!file.exists(sanctuaries_spp_csv)){
  
  # redo
  if (file.exists(sanctuaries_spp_csv)) file.remove(sanctuaries_spp_csv)
  
  sanctuaries_spp <- map(sanctuaries, function(nms){
    nms_spp_csv <- glue("~/github/info-intertidal/data/{toupper(nms)}_species.csv")
    read_csv(nms_spp_csv) %>% 
      mutate(nms = !!nms)}) %>% 
    bind_rows() %>% 
    group_by(sp, sp_name, nms) %>% 
    summarize(
      n = sum(n)) %>% 
    tidyr::spread(nms, n)
  
  stopifnot(length(unique(sanctuaries_spp$sp)) == nrow(sanctuaries_spp))
  
  write_csv(sanctuaries_spp, sanctuaries_spp_csv)  
}