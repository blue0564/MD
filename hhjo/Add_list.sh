#!/bin/bash
# Copyright 2018   Mar WoonHaneg, Heo
#
#  This script is meant to be invoked by Supplement_database.sh
#

:<<END
listPath=local/supplement.tmp/pbs.list
dir=data/musan_speech_test
END

listPath=$1
dir=$2

outDir=`echo $dir | sed 's/musan/supplement/'`

rm -rf $outDir
cp -r $dir $outDir

echo "Add <$listPath> list to existed <$outDir> list"
# read input list file
while read line; do
  # separate wav name from wav path
  for i in $(seq 1 20); do
    wav=`echo $line | cut -d'/' -f$i`
    if [ `echo $wav | grep wav` ]; then
      wavName=`echo $wav | cut -d'.' -f1`
      #echo $wavName
      break 1
    fi
    #echo $i
  done

  # write spk2utt
  #echo $wavName $wavName
  echo $wavName $wavName >> $outDir/spk2utt
  # write utt2spk
  echo $wavName $wavName >> $outDir/utt2spk
  # write wav.scp
  echo $wavName $line >> $outDir/wav.scp

done < $listPath




