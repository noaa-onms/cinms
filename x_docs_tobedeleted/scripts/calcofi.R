
calcofi_plot <- function(
  csv, 
  x_fld       = "year", 
  y_fld       = "avg_larvae_count_per_volume_sampled", 
  y_trans     = "log(y + 1)",
  x_lab       = "Year",
  y_lab       = "ln(mean abundance + 1)",
  title       = NULL,
  yrs_recent  = 5, 
  interactive = T,
  in_loop     = F){
  # csv     = here("data/Anchovy_CINMS.csv")
  # x_fld   = "year"
  # y_fld   = "avg_larvae_count_per_volume_sampled"
  # y_trans = "log(y + 1)"
  # x_lab   = "Year" 
  # y_lab   = "ln(mean abundance + 1)"
  # title   =  "Anchovy - CINMS Region"
  # yrs_recent = 5; interactive=T
  
  library(glue)
  library(dplyr)
  library(lubridate)
  library(readr)
  library(plotly)
  library(htmltools)
  library(rlang)
  library(scales)
  library(stringr)
  
  #browser()
  d <- csv %>% 
    stringr::str_replace_all(" ", "%20") %>% 
    readr::read_csv()
  
  if (nrow(d) == 0) return(NULL)
  
  flds <- list(x = sym(x_fld), y = sym(y_fld))
  d <- select(d, !!!flds)
  
  if (!is.null(y_trans))
    d <- mutate(d, y = !! rlang::parse_expr(y_trans))
  
  z <- filter(d, x < max(x) - lubridate::years(yrs_recent))
  y_avg <- mean(z$y)
  y_sd  <- sd(z$y)
  y_r   <- scales::expand_range(range(d$y), mul=0.05)
  
  g <- ggplot(d, aes(x = x, y = y)) + 
    annotate(
      "rect",
      xmin = max(d$x) - years(yrs_recent), xmax = max(d$x) + months(6),
      ymin = y_r[1], ymax = y_r[2],
      fill  = "lightblue", alpha=0.5) +
    geom_line() + 
    geom_point() + 
    geom_hline(
      yintercept = c(y_avg + y_sd, y_avg,  y_avg - y_sd), 
      linetype   = c("solid", "dashed", "solid"),
      color       = "darkblue") + 
    coord_cartesian(
      xlim = c(
        min(d$x) - months(6),
        max(d$x) + months(6)), expand = F) + 
    theme_light() +
    labs(
      x     = x_lab,
      y     = y_lab,
      title = title)
  
  if (interactive){
    p <- plotly::ggplotly(g)
    if (in_loop){
      # [`ggplotly` from inside `for` loop in `.Rmd` file does not work · Issue #570 · ropensci/plotly](https://github.com/ropensci/plotly/issues/570)
      print(htmltools::tagList(p))
      message(
        "need to add dependencies in R chunk per: \n",
        " - https://github.com/marinebon/calcofi-analysis/blob/6c678b052ded628cf149d5e37a1560e9f5efa6e5/docs/index.Rmd#L595-L615\n",
        " - [`ggplotly` from inside `for` loop in `.Rmd` file does not work · Issue #570 · ropensci/plotly](https://github.com/ropensci/plotly/issues/570)")
    } else {
      p
    }
  } else {
    print(g)
  }
}


calcofi_map <- function(
  geo        = "https://raw.githubusercontent.com/marinebon/calcofi-analysis/master/data/plys_cinms.geojson",
  filter_str = 'ply_code != "SoCal"',
  colors     = c("red", "yellow")
){
  library(sf)
  library(dplyr)
  library(rlang)
  #library(mapview)
  library(leaflet)
  
  plys <- read_sf(geo)
  
  if (!any(is.na(filter_str), is.null(filter_str), nchar(filter_str)==0)){
    # https://edwinth.github.io/blog/dplyr-recipes/
    expr <- rlang::parse_expr(filter_str)
    plys <- dplyr::filter(plys, !! expr)
    plys <- plys %>% 
      mutate(
        area_km2 = st_area(geometry) %>% units::set_units(km^2),
        color    = !!colors) %>% 
      arrange(desc(area_km2))
    # plys %>% st_drop_geometry()
  }
  
  #mapviewOptions(
  #  basemaps = c("Esri.OceanBasemap", "Stamen.TonerLite"))
  
  #mapview(plys, zcol="ply_code")
  leaflet(
    data = plys,
    options = leafletOptions(
      attributionControl = F)) %>% 
    addProviderTiles(providers$Esri.OceanBasemap) %>% 
    addPolygons(
      label = ~ply_code,
      color = ~color, fillColor = ~color,
      fillOpacity = 0.4, weight = 2) %>% 
    addLegend(
      colors = ~color,
      labels = ~ply_code)
}

calcofi_map_caption <- function(){
  '**Figure App.F.12.17.new**. Location of regions from spring season net samples by the California Cooperative Oceanic Fisheries Investigations (CalCOFI) used in analyses of abundance and trends in pelagic resources: Channel Islands National Marine Sanctuary region (purple) includes CalCOFI stations inside and adjacent to CINMS; and Southern California Shelf (yellow) includes all CalCOFI stations over the shelf. Figure: A. Thompson/NOAA, Ben Best/EcoQuants'
  # TODO: move to captions.md and read
}