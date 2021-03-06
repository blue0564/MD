#!/bin/bash
# Copyright 2018   Mar WoonHaneg, Heo
#
#  Input: xxxx.list file
#  Output: wav.scp format file
#
#  This script is meant to be invoked by mix_PBS_AudioSet.sh
#


listPath=$1
#listPath=local/supplement.tmp/pbs.list
output=`echo $listPath | sed 's/.list/.wavScp/'`

rm -f $output

while read line; do
  # separate wav name from wav path
  for i in $(seq 1 20); do
    wav=`echo $line | cut -d'/' -f$i`
    if [ `echo $wav | grep wav` ]; then
      wavName=`echo $wav | cut -d'.' -f1`
      break 1
    fi
  done

  # write wav.scp
  echo $wavName $line >> $output

done < $listPath


