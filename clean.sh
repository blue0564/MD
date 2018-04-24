#!/bin/bash
#
# copyright 2018.04.04. WoonHaeng, Heo
#
# This script clean up the folder and file that is for saving information like
# DNN model, GMM model, MFCC feature, vad result, etc.
# 
# Delete folder and file: Result, model (exp), mfcc, data, test wav file
# 
#

resultFolder='Result*'
mfcc=mfcc
data=data
model=exp

rm -rf $resultFolder
echo "Delete the Result folder"
rm -rf $mfcc
echo "Delete the mfcc feature folder"
rm -rf spec
echo "Delete the spectrogram feature folder"
rm -rf $data
echo "Delete the data folder"
rm -rf $model
echo "Delete the saving model folder"

stop=0
while [ 1 ]; do

  echo -e "Do you want to delete the wav file? [Y/n]: \c"
  read word

  if [ "$word" = "Y" ] || [ "$word" = "y" ]; then
    find . -name *.wav -exec rm {} \;
    echo "Delete the wav file"
    break;
  elif [ "$word" = "N" ] || [ "$word" = "n" ]; then
    break;
  elif [ $stop -ge 5 ]; then
    break;
  fi

  stop=$(($stop+1))

done


