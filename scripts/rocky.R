library(tidyverse)
library(lubridate)
library(readxl)
library(here)
library(glue)
library(fs)
library(sf)
library(mapview)
library(RColorBrewer)
library(dygraphs) # devtools::install_github("rstudio/dygraphs")
library(xts)
here = here::here

#library(rerddap)
# cannot use rerddap b/c login presently required

sanctuaries <- c("cinms", "mbnms", "ocnms")

# data from [ERDDAP](https://oceanview.pfeg.noaa.gov/erddap/login.html),
#   logged in as ben@ecoquants.com,
#   search for "MARINe_ -cciea"
# https://oceanview.pfeg.noaa.gov/erddap/search/index.html?page=1&itemsPerPage=1000&searchFor=MARINe_+-cciea

#dir_pfx     <- here("../info-intertidal")
dir_gdrive <- "/Volumes/GoogleDrive/Shared drives/NMS/data"
dir_pfx     <- file.path(dir_gdrive, "github_info-intertidal_data")

dir_shp     <- file.path(dir_pfx, "shp")
#raw1_csv   <- file.path(dir_pfx, "MARINe_raw_4c1e_9218_7d13.csv")
#raw2_csv   <- file.path(dir_pfx, "MARINe_raw_1c3b_9486_c22d.csv")
raw_csv     <- file.path(dir_pfx, "MARINe_raw_84af_263b_1183.csv")     # 550.2 MB
sscount_csv <- file.path(dir_pfx, "MARINe_sscount_32ad_18f5_c37e.csv") #   1.4 MB
sssize_csv  <- file.path(dir_pfx, "MARINe_sssize_f3df_630e_2c43.csv")  #   3.8 MB
raw_fmt     <- "csv" # or "csvp"
sites_csv   <- file.path(dir_pfx, "MARINe_sites.csv")
mregions_csv <- file.path(dir_pfx, "MARINe_regions.csv")
d_csv       <- file.path(dir_pfx, "sanctuary_species_percentcover.csv")
nms_spp_sscount_csv     <- file.path(dir_pfx, "sanctuary_species_sscount.csv")
sscount_spp_csv         <- file.path(dir_pfx, "sscount_spp.csv")
sscount_spp_methods_csv <- file.path(dir_pfx, "sscount_spp_methods.csv")
raw_n_csv <- file.path(dir_pfx, "raw_summary_n.csv")
spp_csv   <- file.path(dir_pfx, "spp_targets.csv")
#nms_spp_csv <- file.path(dir_pfx, "nms_spp_targets.csv")
nms_spp_csv     <- file.path(dir_pfx, "nms_spp.csv")
nms_spp_rgn_csv <- file.path(dir_pfx, "nms_spp_rgn.csv")
#nms_rgns_csv    <- "https://docs.google.com/spreadsheets/d/1Prm_NxhnRvGTIG7bqw4st8tt0NYnQWZ3/export?format=csv&gid=178828096"
#nms_rgns_cache_csv <- file.path(dir_pfx, "MARINe_graphs.xlsx - sites in regions.csv")
nms_rgns_csv    <- file.path(dir_pfx, "MARINe_graphs.xlsx - sites in regions.csv")

redo <- F # redo <- T

# https://www.eeb.ucsc.edu/pacificrockyintertidal/target/index.html
spp <- read_csv(spp_csv)

nms_rgns <- read_csv(nms_rgns_csv) %>% 
#nms_rgns <- read_csv(nms_rgns_cache_csv) %>% 
  fill(nms) %>% 
  group_by(nms) %>% 
  #fill(bioregion, island) %>% 
  fill(region) %>% 
  mutate(
    rgn = region) # View(nms_rgns)

# TODO: MARINe_sscount_2c08_916b_1ec6.csv: MARINe seastarkat_count_totals
#  species_code: KATTUN 
# later: MARINe_sssize_971e_f4b1_6017.csv: MARINe seastarkat_size_count_totals 
#        
# black-abalone
# black-oystercatcher
# inverts
# key-climate-ocean
# key-human-activities
# ochre-stars PISOCH Ochre Seastar
# owl-limpets




# # old vs new data comparisons (2019-12-14) ----
# raw0        <- read_csv(raw0_csv)                              # 1,722,219 x 25
# names(raw0) <- names(raw0) %>% str_replace(" \\(.*\\)", "")
# hdr         <- read_csv(raw_csv, n_max=1)
# raw         <- read_csv(raw_csv, skip = 2, col_names = names(hdr)) # 1,354 x 25
# range(raw0$time) # "2002-10-18 UTC" "2017-08-21 UTC"
# range(raw$time)  # "2019-08-30 UTC" "2019-08-31 UTC"
# 
# sscount1_csv <- file.path(dir_pfx, "MARINe_sscount_2c08_916b_1ec6.csv")
# sscount2_csv <- file.path(dir_pfx, "MARINe_sscount_1147_c85f_673a.csv")
# sssize1_csv  <- file.path(dir_pfx, "MARINe_sssize_438a_fbe9_efa6.csv")
# sssize2_csv  <- file.path(dir_pfx, "MARINe_sssize_18aa_9665_ac05.csv")
# 
# sscount1 <- read_csv(sscount1_csv)
# names(sscount1) <- names(sscount1) %>% str_replace(" \\(.*\\)", "")
# sscount2_hdr <- read_csv(sscount2_csv, n_max=1)
# sscount2 <- read_csv(sscount2_csv, skip = 2, col_names = names(sscount2_hdr))
# fs::file_info(sscount1_csv)$modification_time # 2019-09-11
# fs::file_info(sscount2_csv)$modification_time # 2019-11-19
# dim(sscount1) # 273 x 22
# dim(sscount2) # 273 x 22
# range(sscount1$time) # 2017-01-01 to 2017-01-01
# range(sscount2$time) # 2019-01-01 to 2019-01-01
# 
# sssize1 <- read_csv(sssize1_csv)
# names(sssize1) <- names(sssize1) %>% str_replace(" \\(.*\\)", "")
# sssize2_hdr <- read_csv(sssize2_csv, n_max=1)
# sssize2 <- read_csv(sssize2_csv, skip = 2, col_names = names(sssize2_hdr))
# fs::file_info(sssize1_csv)$modification_time # 2019-09-11
# fs::file_info(sssize2_csv)$modification_time # 2019-11-19
# dim(sssize1) # 402 x 24
# dim(sssize2) # 434 x 24
# range(sssize1$time) # 2017-01-01 to 2017-01-01
# range(sssize2$time) # 2019-01-01 to 2019-01-01
# 
# sum1_csv <- file.path(dir_pfx, "MARINe_sum_dc16_720d_a67b.csv")
# sum2_csv <- file.path(dir_pfx, "MARINe_sum_4395_f3d7_4b15.csv")
# 
# sum1 <- read_csv(sum1_csv)
# names(sum1) <- names(sum1) %>% str_replace(" \\(.*\\)", "")
# sum2_hdr <- read_csv(sum2_csv, n_max=1)
# sum2 <- read_csv(sum2_csv, skip = 2, col_names = names(sum2_hdr))
# fs::file_info(sum1_csv)$modification_time # 2019-09-11
# fs::file_info(sum2_csv)$modification_time # 2019-11-19
# dim(sum1) # 4543 x 25
# dim(sum2) # 6197 x 25
# range(sum1$time) # 2017-01-01 to 2017-01-01
# range(sum2$time) # 2019-01-01 to 2019-01-01


# functions ----

plot_intertidal_nms <- function(
  d_csv, NMS, spp, sp_name, spp_targets = NULL,
  fld_val = "pct_cover", label_y = "Annual Mean Percent Cover (%)",
  label_x = "Year", nms_skip_regions = c("OCNMS","MBNMS")){
  # NMS = "OCNMS"; spp = "CHTBAL"; sp_name = "Acorn Barnacles"
  # NMS="OCNMS"; spp = c("BARNAC","CHTBAL"); sp_name = "Acorn Barnacles"
  # NMS="OCNMS"; spp = "PELLIM"; sp_name = "Dwarf Rockweed"; nms_skip_regions = c("MBNMS")
  # NMS="CINMS"; spp="CHTBAL"; sp_name="Acorn Barnacles"
  # NMS="MBNMS"; "PELLIM"; "Dwarf Rockweed"
  # NMS="CINMS"; spp="CHTBAL"; sp_name="Acorn Barnacles [target = balanus | chthamalus_balanus]"; spp_targets=c("balanus", "chthamalus_balanus")
  # fld_val = "pct_cover"; label_y = "Annual Mean Percent Cover (%)"; label_x = "Year"; nms_skip_regions = c("OCNMS","MBNMS")
  # d_csv; NMS = "CINMS"; spp ="SILCOM"; sp_name = "Golden Rockweed" ; spp_targets = NULL
  
  #plot_intertidal_nms(nms_spp_sscount_csv, "CINMS", "PISOCH", "Ochre Seastar")
  # d_csv = nms_spp_sscount_csv; NMS = "CINMS"; spp = "PISOCH"; sp_name = "Ochre Seastar"
  # label_x = "Year"; nms_skip_regions = c("OCNMS","MBNMS")
  # spp_targets = NA; fld = "pct_cover"
  # fld_val = "count"; label_y = "Count (annual avg)"
  
  #d_csv; NMS="CINMS"; spp="MYTCAL"; sp_name="California Mussels [target = mytilus]"; spp_targets="mytilus"

  # read in csv with fields site, date, pct_cover|count
  # read_csv(d_csv) %>% names()
  # read_csv(d_csv) %>% select(nms, sp) %>% table()
  d <- read_csv(d_csv) %>% #head() # table(d$nms)
    filter(nms == NMS, sp %in% spp) %>% 
    rename(v = !!fld_val)
  
  if (!is.null(spp_targets)){
    #browser()
    d <- d %>%
      filter(sp_target %in% spp_targets)
  }
  
  d <- d %>%
    group_by(site, date) %>%
    summarize(
      #pct_cover = sum(pct_cover)) %>% 
      #count = sum(count)) %>% 
      v = mean(v)) %>% 
    ungroup()
  
  if (!NMS %in% nms_skip_regions){
    sites_no_rgn <- d %>% filter(site != NMS) %>% anti_join(nms_rgns, by="site") %>% pull(site) %>% unique()
    stopifnot(length(sites_no_rgn) == 0)
    rgns <- nms_rgns %>% filter(nms == NMS) %>% pull(rgn) %>% unique()
  } else {
    rgns = character(0)
  }
  
  if (length(rgns) > 0){
    # avg by region
    d_sites <- d %>% 
      filter(site != NMS) %>% 
      left_join(nms_rgns, by="site") %>% 
      group_by(rgn, date) %>%
      summarize(
        v = mean(v)) %>% 
      ungroup()

    d_allsites <- d %>% 
      filter(site == NMS) %>% 
      mutate(
        rgn = site) %>% 
      select(rgn, date, v)
    
    d <- bind_rows(d_sites, d_allsites)
  } else {
    d <- d %>% 
      mutate(
        rgn = site) %>% 
      select(rgn, date, v)
  }
  
  
  # avg by year and spread
  d <- d %>% 
    mutate(
      yr = year(date)) %>% 
    group_by(rgn, yr) %>% 
    summarize(
      v = mean(v)) %>% 
    spread(rgn, v) # View(d)
  
  # line colors
  #display.brewer.all()
  #display.brewer.pal(ncol(d) - 1, "Set3")
  #ln_colors <- colorRampPalette(brewer.pal(11, "Set3"))(ncol(d) - 1)
  if (ncol(d) - 1 > 12){
    pal <- colorRampPalette(brewer.pal(12, "Set1"))
    ln_colors <- pal(ncol(d) - 1)
  } else {
    ln_colors <- brewer.pal(ncol(d) - 1, "Set3")
  }
  #filled.contour(volcano, col=ln_colors)
  ln_colors[which(names(d) == NMS) - 1] <- "black"
  
  # convert to xts time object
  # x <- select(d, -yr) %>%
  #   as.xts(order.by = ymd(glue("{d$yr}-06-15")))
  
  # plot dygraph
  dygraph(
    #x,
    d, 
    main = glue("{sp_name} in {NMS}"),
    xlab = label_x,
    ylab = label_y) %>%
    dyOptions(
      connectSeparatedPoints = TRUE,
      colors = ln_colors) %>%
    dySeries(NMS, strokeWidth = 3) %>%
    dyHighlight(highlightSeriesOpts = list(strokeWidth = 2)) %>%
    dyRangeSelector(fillColor = " #FFFFFF", strokeColor = "#FFFFFF")
}

map_nms_sites <- function(nms){
  # nms <- "cinms" # mbnms" # "ocnms"
  NMS <- str_to_upper(nms)
  
  # get sites in nms
  sites_nms_shp <- glue("{dir_shp}/{NMS}_sites.shp")
  nms_ply <- get_nms_polygons(nms)
  
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

read_csv_fmt <- function(csv, erddap_format = "csv"){
  # erddap_format = "csv" # or "csvp"
  
  stopifnot(erddap_format %in% c("csv", "csvp"))
  
  if (erddap_format == "csv"){
    # ERDDAP: csv format, remove units from 2nd row
    hdr <- read_csv(csv, n_max=1)
    d <- read_csv(csv, skip = 2, col_names = names(hdr))
  }
  
  if (erddap_format == "csvp"){
    # ERDDAP: csvp format; remove ' (units)' suffix
    d <- read_csv(csv)
    names(d) <- names(d) %>% str_replace(" \\(.*\\)", "")
  }
  d
}

get_sites <- function(raw_csv, sites_csv){
  
  if (!file.exists(sites_csv)){
    
    raw <- read_csv_fmt(raw_csv, raw_fmt)
    
    sites_pts <- raw %>%
      rename(
        site = marine_site_name) %>%
      group_by(site) %>%
      summarize(
        lat = first(latitude),
        lon = first(longitude)) %>%
      st_as_sf(coords = c("lon", "lat"), crs = 4326, remove=F)
    
    sites_pts %>%
      st_set_geometry(NULL) %>%
      write_csv(sites_csv)
  }
  
  read_csv(sites_csv)
}

make_mregions_csv <- function(raw_csv, mregions_csv){
  # [Sites by Region | MARINe](https://marine.ucsc.edu/sites/sites-region/index.html)
  
  raw <- read_csv_fmt(raw_csv, raw_fmt)
  
  # metadata: https://oceanview.pfeg.noaa.gov/erddap/info/MARINe_raw/index.html
  mregions <- raw %>% 
    group_by(bioregion, georegion) %>% 
    #group_by(site_code, marine_site_name, marine_sort_order, state_province, georegion, bioregion) %>% 
    # mpa_region, mpa_designation
    summarize(
      marine_sort_order_min = min(marine_sort_order, na.rm = T),
      marine_sort_order_max = max(marine_sort_order, na.rm = T),
      n_rows = n()) %>% 
    arrange(marine_sort_order_min, bioregion, georegion) 
  
  write_csv(mregions, mregions_csv)
    View(mregions)
}
make_sites_csv <- function(raw_csv, sites_csv){
  raw <- read_csv_fmt(raw_csv, raw_fmt)
  
  sites_pts <- raw %>%
    rename(
      site = marine_site_name) %>%
    group_by(site) %>%
    summarize(
      lat = first(latitude),
      lon = first(longitude)) %>%
    st_as_sf(coords = c("lon", "lat"), crs = 4326, remove = F)
  
  sites_pts %>%
    st_set_geometry(NULL) %>%
    write_csv(sites_csv)
}

make_nms_spp_pctcover <- function(sanctuaries, raw_csv, d_csv, redo = F){
  
  if (!file.exists(raw_n_csv) | redo){
    #head(raw, 1000) %>% View()
    #table(raw$lumping_code)
    #table(raw$target_assemblage)
    
    raw <- read_csv_fmt(raw_csv, raw_fmt)
    
    raw %>% 
      group_by(lumping_code, target_assemblage) %>% 
      summarize(n = n()) %>% 
      write_csv(raw_n_csv)
  }
  
  for (i in 1:length(sanctuaries)){ # i = 1
    
    # set sanctuary variables
    nms <- sanctuaries[i] # nms <- "cinms" # "mbnms" # "ocnms"
    NMS <- str_to_upper(nms)
    
    message(glue("{i} of {length(sanctuaries)} nms: {NMS}"))
    
    # get sites in nms
    sites_nms_shp <- file.path(dir_pfx, glue("shp/{NMS}_sites.shp"))
    if (!file.exists(sites_nms_shp)){
      nms_ply <- get_nms_polygons(nms)
      sites_nms_pts <- sites_pts %>%
        st_intersection(
          nms_ply %>% 
            st_buffer(0.01))
      write_sf(sites_nms_pts, sites_nms_shp)
    }
    sites_nms_pts <- read_sf(sites_nms_shp)
    
    # plot map of sanctuary and sites
    # nms_ply <- get_nms_polygons(nms)
    # m <- mapview(nms_ply) + sites_nms_pts
    # print(m)
    
    nms_spp_csv <- file.path(dir_pfx, glue("{NMS}_species.csv"))
    if (!file.exists(nms_spp_csv) | redo){
      
      #browser()
      
      nms_spp <- raw %>%
        rename(
          site      = marine_site_name,
          sp        = lumping_code,
          sp_name   = lumping_name,
          sp_target = target_assemblage) %>% 
        filter(
          site %in% sites_nms_pts$site) %>% 
        group_by(sp, sp_name, sp_target) %>% 
        summarize(n = n())
      
      #stopifnot(length(unique(nms_spp$sp)) == nrow(nms_spp))
      
      write_csv(nms_spp, nms_spp_csv)
    }
    nms_spp <- read_csv(nms_spp_csv)
    
    # iterate over species-targets
    for (j in 1:nrow(nms_spp)){ # j = 1
      
      #browser()
      
      # set species variables
      sp        <- nms_spp$sp[j]
      #sp_targets <- str_split(spp$sp_target[j], "\\|", simplify = T)[1,]
      sp_target <- nms_spp$sp_target[j]
      sp_name   <- nms_spp$sp_name[j]
      
      message(glue("  {j} of {nrow(nms_spp)} spp: {sp_name} ({sp}), target = {sp_target}"))
    
      # filter for nms-sp-target
      d_sites <- raw %>%
        rename(site = marine_site_name) %>%
        filter(
          site %in% sites_nms_pts$site,
          lumping_code == sp,
          #target_assemblage %in% sp_targets,
          target_assemblage == sp_target)
      
      # next sp if empty
      if (nrow(d_sites) == 0) next()
      
      # average across plots for each site-sp-target-date
      d_sites <- d_sites %>%
        mutate(
          date = ymd(time)) %>%
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
          nms       = NMS,
          sp        = sp,
          sp_target = sp_target) # View(d)
      
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

make_nms_spp_sscount <- function(sanctuaries, sscount_csv, nms_spp_sscount_csv, redo = F){
  
  sscount <- read_csv_fmt(sscount_csv)
  
  if (!file.exists(sscount_spp_csv) | redo){
    
    sscount %>% 
      group_by(species_code, target_assemblage) %>% 
      summarize(n_rows = n()) %>% 
      write_csv(sscount_spp_csv)
    
    sscount %>% 
      group_by(species_code, target_assemblage, method_code) %>% 
      summarize(n_rows = n()) %>% 
      write_csv(sscount_spp_methods_csv)
  }
  
  for (i in 1:length(sanctuaries)){ # i = 1
    
    # set sanctuary variables
    nms <- sanctuaries[i] # nms <- "cinms" # "mbnms" # "ocnms"
    NMS <- str_to_upper(nms)
    
    message(glue("{i} of {length(sanctuaries)} nms: {NMS}"))
    
    # get sites in nms
    sites_nms_shp <- file.path(dir_pfx, glue("shp/{NMS}_sites.shp"))
    if (!file.exists(sites_nms_shp)){
      nms_ply <- get_nms_polygons(nms)
      sites_nms_pts <- sites_pts %>%
        st_intersection(
          nms_ply %>% 
            st_buffer(0.01))
      write_sf(sites_nms_pts, sites_nms_shp)
    }
    sites_nms_pts <- read_sf(sites_nms_shp)
    
    # plot map of sanctuary and sites
    # nms_ply <- get_nms_polygons(nms)
    # m <- mapview(nms_ply) + sites_nms_pts
    # print(m)
    
    nms_spp_csv <- file.path(dir_pfx, glue("{NMS}_sscount_species.csv"))
    if (!file.exists(nms_spp_csv) | redo){
      
      #browser()
      nms_spp <- sscount %>%
        rename(
          site      = marine_site_name,
          sp        = species_code,
          sp_method = method_code) %>% 
        filter(
          site %in% sites_nms_pts$site) %>% 
        group_by(sp, sp_method) %>% 
        summarize(n = n())
      
      #stopifnot(length(unique(nms_spp$sp)) == nrow(nms_spp))
      
      write_csv(nms_spp, nms_spp_csv)
    }
    nms_spp <- read_csv(nms_spp_csv)
    
    # iterate over species-targets
    for (j in 1:nrow(nms_spp)){ # j = 1
      
      # set species variables
      sp        <- nms_spp$sp[j]
      sp_method <- nms_spp$sp_method[j]
      
      message(glue("  {j} of {nrow(nms_spp)} sp: {sp}, method = {sp_method}"))
      
      # filter for nms-sp-method
      d_sites <- sscount %>%
        rename(site = marine_site_name) %>%
        filter(
          site %in% sites_nms_pts$site,
          species_code == sp,
          method_code  == sp_method)
      #View(d_sites)
      
      # next sp if empty
      if (nrow(d_sites) == 0) next()
      
      # average across plots for each site-sp-target-date
      d_sites <- d_sites %>%
        mutate(
          date = ymd(time)) %>%
        group_by(site, date) %>%
        summarize(
          count = mean(total)) # View(d_sites)
      
      # average across sites to nms-year
      d_nms <- d_sites %>%
        mutate(
          date = date(glue("{year(date)}-06-15"))) %>%
        group_by(date) %>%
        summarize(
          count = mean(count)) %>%
        ungroup() %>%
        mutate(
          site = NMS) # View(d_nms)
      
      # combine sites and sanctuary annual average
      d <- bind_rows(
        d_sites,
        d_nms) %>%
        mutate(
          nms       = NMS,
          sp        = sp,
          sp_method = sp_method) # View(d)
      
      # write data to csv
      if (i == 1 & j == 1){
        write_csv(d, nms_spp_sscount_csv)
      } else {
        write_csv(d, nms_spp_sscount_csv, append=T)
      }
      
      # generate timeseries plot
      #p <- plot_intertidal_nms(d_csv, NMS, sp_name)
      #print(p)
    }
  }
}

#ocnms <- get_nms_polygons("ocnms")
#map_nms_sites("ocnms")

if (!file.exists(d_csv) | redo){
  # NOTE: remake d_csv if adding a sanctuary or species
  make_nms_spp_pctcover(sanctuaries, raw_csv, d_csv, redo = redo)
}

if (!file.exists(nms_spp_sscount_csv) | redo){
  # NOTE: remake d_csv if adding a sanctuary or species
  make_nms_spp_sscount(sanctuaries, sscount_csv, nms_spp_sscount_csv, redo = redo)
}

if (!file.exists(nms_spp_csv) | redo){
  
  # redo
  if (file.exists(nms_spp_csv)) file.remove(nms_spp_csv)
  
  nms_spp <- map(sanctuaries, function(nms){
    nms_spp_csv <- glue("{dir_pfx}/{toupper(nms)}_species.csv")
    read_csv(nms_spp_csv) %>% 
      mutate(nms = !!nms)}) %>% 
    bind_rows() %>% 
    group_by(sp, sp_name, sp_target, nms) %>% 
    summarize(
      n = sum(n)) %>% 
    tidyr::spread(nms, n)
  
  #stopifnot(length(unique(nms_spp$sp)) == nrow(nms_spp))
  
  write_csv(nms_spp, nms_spp_csv)  
}

