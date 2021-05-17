# Container image that runs your code  
FROM rocker/geospatial:latest

# install extra R packages 
RUN install2.r --error \
  dygraphs \
  fs \
  glue \
  here \
  librarian \
  lubridate \
  rerddap
  
RUN installGithub.r marinebon/infographiqR
RUN installGithub.r noaa-onms/onmsR