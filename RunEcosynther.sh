#!/bin/bash
#
# RunBundler.sh
#   copyright 2008 Noah Snavely
#
# A script for preparing a set of image for use with the Bundler 
# structure-from-motion system.
#
# Usage: RunBundler.sh [image_dir]
#
# The image_dir argument is the directory containing the input images.
# If image_dir is omitted, the current directory is used.
#

# Set this variable to your base install path (e.g., /home/foo/bundler)
# BASE_PATH="TODO"

BASE_PATH=$(dirname $(which $0));
IMAGE_BASE_PATH=$PWD;

SIFTGPU_PATH="/home/greivin/Code/ecosynther_v0.8/ecosynther_v0.8/Ecosynther_v0.8_GPS_filter/EcosyntherFull/CustomizeGPUSIFT";

timestamp=`date`
echo "$timestamp Starting RunEcosynther" >> timelog

if [ $BASE_PATH == "TODO" ]
then
    echo "Please modify this script (RunBundler.sh) with the base path of your bundler installation.";
    exit;
fi

EXTRACT_FOCAL=$BASE_PATH/bin/extract_focal.pl

OS=`uname -o`

if [ $OS == "Cygwin" ]
then
    MATCHKEYS=$BASE_PATH/bin/KeyMatchFull.exe
    BUNDLER=$BASE_PATH/bin/Bundler.exe
else
    MATCHKEYS=$BASE_PATH/bin/KeyMatchFull
    BUNDLER=$BASE_PATH/bin/bundler
fi

TO_SIFT=$BASE_PATH/bin/ToSift.sh

timestamp=`date`
echo "$timestamp Starting GPUSIFT & Matching" >> timelog

IMAGE_DIR="."

if [ $# -eq 1 ]
then
    echo "Using directory '$1'"
    IMAGE_DIR=$1
fi

# Rename ".JPG" to ".jpg"
for d in `ls -1 $IMAGE_DIR | egrep ".JPG$"`
do 
   mv $IMAGE_DIR/$d $IMAGE_DIR/`echo $d | sed 's/\.JPG/\.jpg/'`
done

echo "[- Create list of images -]"
# Create the list of images
find $IMAGE_DIR -maxdepth 1 | egrep ".jpg$" | sort > list_tmp.txt
$EXTRACT_FOCAL list_tmp.txt
cp prepare/list.txt .

echo "[- Copy list_tmp.txt to SiftGPU/bin folder -]"
cp list_tmp.txt $SIFTGPU_PATH/SiftGPU/bin/

echo "[- Copy images to SiftGPU/bin folder -]"
cp *.jpg $SIFTGPU_PATH/SiftGPU/bin/

echo "[- Enter SiftGPU/bin folder -]"
cd $SIFTGPU_PATH/SiftGPU/bin/

echo "[- Execute GPU SIFT and matching -]"
./SimpleSIFT

EXTENSION=".gz"


##
rename 's/.jpg$/.key/' *.jpg
##

for d in `ls -1 $IMAGE_DIR | egrep "key$"` #for d in `ls -1 $IMAGE_DIR | egrep "jpg$"`
do
	key_file=`echo $d` #key_file=`echo $d | sed 's/jpg$/key/'`
	echo "gzip -f $key_file"
	gzip -f $key_file
	mv $key_file$EXTENSION $IMAGE_BASE_PATH
done	

#rm *.jpg    
rm list_tmp.txt

mv matches.init.txt $IMAGE_BASE_PATH

cd $IMAGE_BASE_PATH

timestamp=`date`
echo "$timestamp Done: GPUSIFT & Matching" >> timelog

# Generate the options file for running bundler 
mkdir bundle
rm -f options.txt

echo "--match_table matches.init.txt" >> options.txt
echo "--output bundle.out" >> options.txt
echo "--output_all bundle_" >> options.txt
echo "--output_dir bundle" >> options.txt
echo "--variable_focal_length" >> options.txt
echo "--use_focal_estimate" >> options.txt
echo "--constrain_focal" >> options.txt
echo "--constrain_focal_weight 0.0001" >> options.txt
echo "--estimate_distortion" >> options.txt
echo "--run_bundle" >> options.txt

timestamp=`date`
echo "$timestamp Starting Bundle Adjustment" >> timelog

# Run Bundler!
echo "[- Running Bundler -]"
rm -f constraints.txt
rm -f pairwise_scores.txt

$BUNDLER list.txt --options_file options.txt > bundle/out

# valgrind --log-file=valgrind.output --tool=memcheck $BUNDLER list.txt --options_file options.txt > bundle/out

#use valgrind to profile bundler program
#valgrind --tool=callgrind --trace-children=yes $BUNDLER list.txt --options_file options.txt > bundle/out

timestamp=`date`
echo "$timestamp Done: Bundle Adjustment" >> timelog

timestamp=`date`
echo "$timestamp [- Done -]" >> timelog


