#!/bin/bash

# you don't need change the configuration. by default
# this config is working as long as you have enough storage.
# all you need just change the region, and RAM allocation.
# for file more than 20GB, you need 13 GB of RAM.
# will add more feature to join multiple pbf file into one file

# choose region, you can choose country or continent.
# if you want add country, you need to add continent as prefix
# e.g add italy, then you should set "europe/italy", "asia/indonesia"
# and if its a continent, you anly need named continent
# e.g "europe", "asia", "africa"
REGION=asia/indonesia

# make sure RAID is working, because maps always spend many space
BASE_PATH=/cache/osm

#GH_URL=https://github.com/graphhopper/graphhopper.git
GH_URL=https://github.com/kahidna/old-graphhopper.git
REPO_NAME=$(echo $GH_URL|rev|cut -d "/" -f1|rev|cut -d "." -f1)
GH_FOLDER=$BASE_PATH/$(echo $GH_URL|rev|cut -d "/" -f1|rev|cut -d "." -f1|cut -d "-" -f2)

#suffix name always be like this
SUFFIX=latest.osm.pbf
MAPS_FILE=$REGION-$SUFFIX
MAPS_PATH=$BASE_PATH/maps

#path for inside container and any variable name for container of graphhopper
CONTAINER_MAPS_FILE=$(echo $MAPS_FILE| cut -d "/" -f2)
CONTAINER_NAME="my_graphhopper"
CONTAINER_HOSTNAME="my-graphhopper"
CONTAINER_PORT="8989"

# I think geofabrik is the most easy to download new file using wget
URL=http://download.geofabrik.de/$MAPS_FILE

# RAM allocation in GigaByte
RAM_ALLOC=5

# setup the path
mkdir -vp $MAPS_PATH

echo ""
echo "Map file specificationthat will be downloaded "
echo "Map file name = $(echo $REGION| cut -d "/" -f2)"
echo "Map file URL = $URL"
echo "Downloading map file"
cd $MAPS_PATH
wget $URL

echo "Clone graphhopper repository"
cd $BASE_PATH;
echo "removing old repo file"
rm -rvf $GH_FOLDER

echo "Clone graphhopper repository"
git clone --recursive $GH_URL
echo "renaming the repository since its name have \'old\' word"
mv $BASE_PATH/$REPO_NAME $GH_FOLDER
cd $GH_FOLDER

echo "upgrading memory allocation to $RAM_ALLOC GB"
STRING="export JAVA_OPTS=\"-Xmx"$RAM_ALLOC"g -Xms"$RAM_ALLOC"g\""
sed "2i $STRING" graphhopper.sh --in-place

echo "build the docker file"
docker build -t graphhopper:master .

echo ""
echo "start build graphhopper service. . . "
docker run -d -it -p $CONTAINER_PORT:8989 --name $CONTAINER_NAME -h $CONTAINER_HOSTNAME -v $GH_FOLDER/graphhopper.sh:/graphhopper/graphhopper.sh -v $MAPS_PATH:/data graphhopper:master ./graphhopper.sh web  /data/$CONTAINER_MAPS_FILE

# delay to make sure container running first before we check it.
sleep 5

echo ""
echo "here is list of all container"
docker ps -a

echo ""
echo "end of script"
echo ""
