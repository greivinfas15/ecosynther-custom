#!/bin/bash

# Call this script in the current directory where all the images are

# Usage: RunSFM.sh [IMAGES_PER_CLUSTER=100] [CPU_CORES=8] [MAX_MATCHING_SEQ=-1]
# IMAGES_PER_CLUSTER is used by CMVS/PMVS2
# CPU_CORES is used by CMVS/PMVS2
# MAX_MATCHING_SEQ is used by SiftMatcher to limit the number of images to match against, useful if the images were taken sequentially (eg. video) 

# Defaults
IMAGES_PER_CLUSTER=100
CPU_CORES=8

ARGC=$#  # Number of args, not counting $0

if [ $ARGC -ge 2 ]
then
    IMAGES_PER_CLUSTER=$1
fi

if [ $ARGC -ge 3 ]
then
    CPU_CORES=$2
fi

BASE_PATH=$(dirname $(which $0));
BUNDLER_PATH="/home/grfallas/Code/ecosynther_v0.8/ecosynther_v0.8/Ecosynther_v0.8_GPS_filter/EcosyntherFull/bundler-v0.4-source"
GPUSIFT_PATH="/home/grfallas/Code/ecosynther_v0.8/ecosynther_v0.8/Ecosynther_v0.8_GPS_filter/EcosyntherFull/CustomizeGPUSIFT/SiftGPU"
CMVS_PATH=$BASE_PATH/cmvs/program/main
GPSFILTER_PATH="/home/grfallas/Code/ecosynther_v0.8/GPSFilter"

python $GPSFILTER_PATH/GPS_camera_telem_interp.py GPS_positions.txt

echo "Please enter the mission track width:"
read width

python $GPSFILTER_PATH/photoMatch.py rough_camera_XYZ_from_GPS.txt $width
cp pointMatches.txt $GPUSIFT_PATH/bin

$BUNDLER_PATH/RunEcosynther.sh .
$BUNDLER_PATH/bin/Bundle2PMVS list.txt bundle/bundle.out

BUNDLER_BIN_PATH=$BUNDLER_PATH/bin

IMAGE_DIR="."

timestamp=`date`
echo "$timestamp Starting Densification" >> $IMAGE_DIR/timelog

sh pmvs/prep_pmvs.sh $BUNDLER_BIN_PATH

$CMVS_PATH/cmvs pmvs/ $IMAGES_PER_CLUSTER $CPU_CORES
$CMVS_PATH/genOption pmvs/

cp pmvs/option-* .

for i in option-*
do
	if [ -f "$i" ]
       then
               $CMVS_PATH/pmvs2 pmvs/ $i
		#echo "$i"
       else
		echo "quiting"
               break
       fi
done

export IMAGE_DIR
sh $BASE_PATH/mergePLY.sh

timestamp=`date`
echo "$timestamp Done: Densification" >> $IMAGE_DIR/timelog

echo "[- Done: Densification -]"
echo "The model patches and a merged dense point cloud (dense.ply) can be found in pmvs/models"
