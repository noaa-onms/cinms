# Container image that runs your code  
FROM rocker/geospatial:latest

# update git
RUN apt-get update; apt-get install git

# install extra R packages 
RUN install2.r --error \
  dygraphs \
  fs \
  glue \
  here \
  lubridate \
  rerddap \
  tidyverse

RUN installGithub.r marinebon/nms4r
