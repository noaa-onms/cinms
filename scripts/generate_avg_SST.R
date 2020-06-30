library(here)
library(rgdal)
library(raster)

# A slight variation of a function found in rocky.R. This function gets the polygon 
# for a National Marine Sanctuary
get_nms_ply <- function(nms){
  
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

# The following draft function generates the mean SST for the Channel Island NMS for a given
# month. All parameters going into mean_SST have to be given as characters, with year being 
# four digits and month being two digits. Currently, the only value for sanctuary that does
# anything is "cinms".

mean_SST <- function (sanctuary, year, month) {
  
  # Get the polygons for the sanctuary.
  sanctuary_area <- get_nms_ply(sanctuary)
  
  if (sanctuary == "cinms"){
    south_bound_lat <- "33.25"
    north_bound_lat <- "34.5"
    east_bound_long <- "-118.75"
    west_bound_long <- "-120.75"
  }
  
  # Create the URL link to pull the temperature data from NOAA for the right month.
  # Note that the data is coming back in csv form, because I couldn't get a geotif 
  # to load properly in R, for some reason.
  # erddap_url = paste0("https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.csv?analysed_sst[(", year, "-", month, "-01T09:00:00Z):1:(", year, "-", month, "-28T09:00:00Z)][(33.25):1:(34.5)][(-120.75):1:(-118.75)]")
  
  erddap_url = paste0("https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.csv?analysed_sst[(", year, "-", month, "-01T09:00:00Z):1:(", year, "-", month, "-28T09:00:00Z)][(", south_bound_lat, "):1:(", north_bound_lat, ")][(", west_bound_long, "):1:(", east_bound_long, ")]")
  
  # Get the data in csv form
  raw_erddap_csv <-read.csv(erddap_url , header = T)
  
  # Create a data frame with the lat, long, and temp data. This isn't a tibble because
  # I was getting annoying errors with tibbles that I didn't want to deal with
  erddap_data  <- data.frame(longitude = as.numeric(raw_erddap_csv[-1,3]), latitude = as.numeric(raw_erddap_csv[-1,2]), sst = as.numeric(raw_erddap_csv[-1,4]))
  
  # Convert the data frame into a SST raster 
  SST_map <- rasterFromXYZ(erddap_data, res = c(0.01, 0.01), crs= "+init=epsg:4326")
  
  # Overlay the Sanctuary polygon over the raster and pull the overlaying temperature values
  extracted_SST<- extract(SST_map, sanctuary_area, method='simple')
  
  # Create a vector of all of the temperatures, take the mean of those temperatures, and that
  # is what the function returns
  all_temps <- unlist(extracted_SST)
  return(mean(all_temps))
}
