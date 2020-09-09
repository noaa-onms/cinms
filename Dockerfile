# Container image that runs your code  
FROM rocker/geospatial:latest

# install extra R packages 
RUN install2.r --error \
  dygraphs \
  fs \
  glue \
  here \
  lubridate \
  rerddap
  
RUN installGithub.r marinebon/nms4r
