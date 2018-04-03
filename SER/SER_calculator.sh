#!/bin/bash

#dataPath=/home/whheo/ETRI/contents/Mask
#dectResultFolder=/home/whheo/ETRI/music_detection/detection_result
#rttmFolder=/home/whheo/ETRI/contents/annotation

annotationFolder=$1
dectResultFolder=$2
rttmFolder=$3

mkdir -p $rttmFolder
#chmod 755 -R $dectResultFolder/*

concat_ref_rttm=""
concat_sys_rttm=""
for LINE in `ls $dectResultFolder/*`; do
  filename=`basename $LINE`
  wavName=${filename%.*}  # file name extraction

  # convert from praat format to rttm format (reference)
  perl praat2rttm.pl $annotationFolder/$wavName.TextGrid $rttmFolder/$wavName.Numbrttm
  perl mapping_class.pl class.conf $rttmFolder/$wavName.Numbrttm $rttmFolder/ref_$wavName.rttm
  rm $rttmFolder/$wavName.Numbrttm

  # convert from detection result to rttm format (system output)
  perl sys_duration.pl $dectResultFolder/$wavName.result $dectResultFolder/$wavName.temp 0.125 0.05
  #perl sys_trans_2c_rttm.pl $dectResultFolder/$wavName.temp $rttmFolder/sys_$wavName.rttm
  perl sys_trans_rttm.pl $dectResultFolder/$wavName.temp $rttmFolder/sys_$wavName.rttm
  rm $dectResultFolder/$wavName.temp


  concat_ref_rttm="$concat_ref_rttm $rttmFolder/ref_$wavName.rttm"
  concat_sys_rttm="$concat_sys_rttm $rttmFolder/sys_$wavName.rttm"
done

#echo $concat_ref_rttm
#echo $concat_sys_rttm

concatenation_script.pl $concat_ref_rttm $rttmFolder/ref_combined.rttm
concatenation_script.pl $concat_sys_rttm $rttmFolder/sys_combined.rttm

perl md-eval-v21.pl -ac -c 0.01 -r $rttmFolder/ref_combined.rttm -s $rttmFolder/sys_combined.rttm

