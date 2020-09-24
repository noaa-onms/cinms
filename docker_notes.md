
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

docker tag 415896bca0ec bdbest/nms:0.1
docker push bdbest/nms:0.1
```

## interactively work inside container

```
docker exec -it cinms bash
cd /home/rstudio
git clone https://github.com/marinebon/cinms.git
cd cinms
Rscript -e 'source("entrypoint.r")'
```

## git tag

```bash
git tag docker-v02
git push origin --tags
```


git clone https://scuzzlebuzzle:<MYTOKEN>@github.com/scuzzlebuzzle/ol3-1.git --branch=gh-pages gh-pages
That will add your credentials to the remote created when cloning the repository. Unfortunately, however, you have no control over how Travis clones your repository, so you have to edit the remote like so.

# After cloning
cd gh-pages
git remote set-url origin https://scuzzlebuzzle:<MYTOKEN>@github.com/scuzzlebuzzle/


Syncing repository: marinebon/cinms
Getting Git version info
  Working directory is '/__w/cinms/cinms'
  /usr/bin/git version
  git version 2.11.0
Deleting the contents of '/__w/cinms/cinms'
The repository will be downloaded using the GitHub REST API
To create a local Git repository instead, add Git 2.18 or higher to the PATH
Downloading the archive
Writing archive to disk
Extracting the archive
