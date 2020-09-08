# Container image that runs your code  
FROM rocker/geospatial:latest

# install extra R packages 
RUN install2.r --error \
  fs \
  glue \
  here \
  lubridate \
  rerddap \
  tidyverse 
  
RUN installGithub.r marinebon/nms4r

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.r /entrypoint.r

# Code file to execute when the docker container starts up (`entrypoint.sh`)
CMD R -e "source('/entrypoint.r')"
#ENTRYPOINT ["/entrypoint.r"]
