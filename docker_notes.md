
Ben trying docker on his laptop:

Run in detached mode

```bash
# cd to where Dockerfile lives
cd /Users/bbest/github/cinms

# build image with a tag
docker build --tag cinms:1.0 .

# run a container using the image in detached mode so still on
docker run --detach --name cinms cinms:1.0

# check running containers
docker ps -a

# but exited?
# 59 seconds ago      Exited (1) 56 seconds ago

# so look at the logs
docker logs cinms
```

Seeing error:

```
[1] "Starting..."
Error: [ENOENT] Failed to remove '//data/cinms.zip': no such file or directory
In addition: Warning messages:
1: replacing previous import ‘dplyr::collapse’ by ‘glue::collapse’ when loading ‘nms4r’
2: In download.file(nms_url, nms_zip) :
  URL https://sanctuaries.noaa.gov/library/imast/cinms_py2.zip: cannot open destfile '//data/cinms.zip', reason 'No such file or directory'
3: In download.file(nms_url, nms_zip) : download had nonzero exit status
4: In unzip(nms_zip, exdir = shp_dir) :
  error 1 in extracting from zip file
Execution halted
```

Turn off the offending line of code:

```r
nms4r::generate_latest_SST("cinms","jplMURSST41mday", "sst", c("mean", "sd"))
```

```bash
# rm and rerun
docker rm cinms

docker build --tag cinms:1.0 .
docker run --detach -p 8787:8787 -e PASSWORD=c1nms --name cinms cinms:1.0
docker ps -a
```


```bash
docker run --detach -p 8787:8787 -e PASSWORD=c1nms --name rstudio-shiny bdbest/rstudio-shiny
docker pull bdbest/rstudio-shiny
```

## push image to docker hub

```bash
docker login --username=bdbest
docker images
docker tag 3b0dd068147d bdbest/cinms:1.0
docker push bdbest/cinms:1.0
```

## interactively work inside container

```
docker exec -it cinms bash
cd /home/rstudio
git clone https://github.com/marinebon/cinms.git
cd cinms
Rscript -e 'source("entrypoint.r")'
```
