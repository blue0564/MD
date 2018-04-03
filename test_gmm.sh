#!/bin/bash
# Copyright 2015   David Snyder
# Apache 2.0.
#

. cmd.sh
. path.sh
set -e
mfccdir=`pwd`/mfcc
vaddir=`pwd`/vad
dataType="drama"
#dataType="drama_ICA"
resultDir=`pwd`/Result_gmm_$dataType
serResultFolder=$resultDir/SERresult
rttmFolder=$resultDir/RTTM
annotationFolder=`pwd`/Databases/data_$dataType/Annotation

mfcc="20"

frameSize="50"
ser_segment_margin=0.05

windowSize="0.125"

stage=1

twoClassMode=0
if [ $twoClassMode -eq 1 ]; then
  serResultFolder=$resultDir/SERresult_2c
  rttmFolder=$resultDir/RTTM_2c
  annotationFolder=`pwd`/Databases/data_$dataType/Annotation_2c
fi

# preprocessing for training vad with GMM (MUSAN)
if [ $stage -le -1 ]; then
  ## Generate mixed data 25h 36m(99200s)
  #hhjo/mixed_DB.sh --total_time 99200
  #hhjo/append_mixed.sh /home/hhjo/bn_music_speech_test/v1/Database/musan data
  hhjo/data_bn.sh ./Databases/data_$dataType data/data_$dataType

  ## Test-data MFCC feature extraction
  steps/make_mfcc.sh --mfcc-config conf/mfcc_$windowSize\_$mfcc.conf --nj 1 --cmd "$train_cmd" \
    data/data_$dataType exp/make_mfcc $mfccdir
  utils/fix_data_dir.sh data/data_$dataType


  #hhjo/delete_vad_file.sh data/data_$dataType

  ## Calculate the energy-VAD of test data
  sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 1 --cmd "$train_cmd" \
    data/data_$dataType exp/make_vad $vaddir
fi

# Predict probability using GMM-model
if [ $stage -le 0 ]; then
  ## 13,20 Mfcc
  ## 8,16,32,64 GMM log likelihood
  datadir=data/data_${dataType}
  sid/compute_vad_decision_gmm.sh --nj 1 --cmd "$train_cmd" \
   --merge-map-config conf/merge_vad_map.txt --use-energy-vad true \
   $datadir \
   exp/model/full_ubm_noise/ exp/model/full_ubm_speech/ \
   exp/model/full_ubm_music/ exp/model/full_ubm_mixed/ \
   exp/vad_gmm exp/vad_gmm
fi

## convert test result format from kaldi to rttm
# transrate ark to txt in test result
if [ ! -e $resultDir/temp/ ];then
 mkdir -p $resultDir/temp/
fi
if [ ! -e $rttmFolder ];then
 mkdir -p $rttmFolder
fi
copy-vector ark:exp/vad_gmm/vad_merged_data_$dataType.1.ark ark,t:$resultDir/temp/data_$dataType.result
copy-vector ark:exp/vad_gmm/vad_merged_data_$dataType.1.ark ark,t:exp/vad_gmm/data_$dataType.result

# smooth test result
if [ $windowSize == 0.025 ];then
  shiftSize=0.01
elif [ $windowSize == 0.125 ];then
  shiftSize=0.05   
else
  shiftSize=0.1
fi
hhjo/smoothing.pl $resultDir/temp/data_$dataType.result \
  $resultDir/temp/data_$dataType.smResult $frameSize
# convert from result per frame to result per time
hhjo/sys_duration.pl $resultDir/temp/data_$dataType.smResult \
  $resultDir/temp/data_$dataType.timeResult $windowSize $shiftSize

# except silence
hhjo/sys_duration_nosil.pl $resultDir/temp/data_$dataType.timeResult \
  $resultDir/temp/data_$dataType.noSilTimeResult
# convert to rttm format
if [ $twoClassMode -eq 1 ]; then 
    echo "2class"
    perl hhjo/sys_trans_2c_rttm.pl $resultDir/temp/data_$dataType.noSilTimeResult $rttmFolder/sys_combined.rttm
  else
    echo "5class"
    perl hhjo/sys_trans_rttm.pl $resultDir/temp/data_$dataType.noSilTimeResult $rttmFolder/sys_combined.rttm
fi

## convert reference file from praat format to rttm format
echo "hhjo/praat2rttm.pl $annotationFolder/mask_00001_700K.TextGrid $resultDir/temp/mask_00001_700K.numrttm"
hhjo/praat2rttm.pl $annotationFolder/mask_00001_700K.TextGrid $resultDir/temp/mask_00001_700K.numrttm
hhjo/mapping_class.pl conf/class.conf $resultDir/temp/mask_00001_700K.numrttm $resultDir/temp/mask_00001_700K.rttm
#rm $resultDir/temp/mask_00001_700K.numrttm
hhjo/praat2rttm.pl $annotationFolder/mask_00002_700K.TextGrid $resultDir/temp/mask_00002_700K.numrttm
hhjo/mapping_class.pl conf/class.conf $resultDir/temp/mask_00002_700K.numrttm $resultDir/temp/mask_00002_700K.rttm
#rm $resultDir/temp/mask_00002_700K.numrttm
hhjo/praat2rttm.pl $annotationFolder/mask_00003_700K.TextGrid $resultDir/temp/mask_00003_700K.numrttm
hhjo/mapping_class.pl conf/class.conf $resultDir/temp/mask_00003_700K.numrttm $resultDir/temp/mask_00003_700K.rttm
#rm $resultDir/temp/mask_00003_700K.numrttm

# concatenate
cat $resultDir/temp/mask_00001_700K.rttm > $rttmFolder/ref_combined.rttm
cat $resultDir/temp/mask_00002_700K.rttm >> $rttmFolder/ref_combined.rttm
cat $resultDir/temp/mask_00003_700K.rttm >> $rttmFolder/ref_combined.rttm


## SER
if [ ! -e $serResultFolder ];then
 mkdir -p $serResultFolder
fi
perl hhjo/md-eval-v21.pl -ac -c $ser_segment_margin -r $rttmFolder/ref_combined.rttm -s $rttmFolder/sys_combined.rttm 
mv result.txt $serResultFolder/result_$(date +%Y%m%d)_$(date +%H%M).txt




:<< END
# smooth test result
if [ $windowSize == 0.025 ];then
  shiftSize=0.01
elif [ $windowSize == 0.125 ];then
  shiftSize=0.05   
else
  shiftSize=0.1
fi
hhjo/smoothing.pl $resultDir/temp/data_$dataType.result \
  $resultDir/temp/data_$dataType.smResult $frameSize
# convert from result per frame to result per time
hhjo/sys_duration.pl $resultDir/temp/data_$dataType.smResult \
  $resultDir/temp/data_$dataType.timeResult $windowSize $shiftSize

#hhjo/sys_duration.pl $resultDir/temp/data_$dataType.result \
#  $resultDir/temp/data_$dataType.timeResult $windowSize $shiftSize
# except silence
hhjo/sys_duration_nosil.pl $resultDir/temp/data_$dataType.timeResult \
  $resultDir/temp/data_$dataType.noSilTimeResult
# convert to rttm format
hhjo/sys_trans_rttm.pl $resultDir/temp/data_$dataType.noSilTimeResult \
  $resultDir/rttm/sys_combined.rttm

## convert reference file from praat format to rttm format
hhjo/praat2rttm.pl Databases/data_drama/ref/mask_00001_700K.TextGrid $resultDir/temp/mask_00001_700K.numrttm
hhjo/mapping_class.pl conf/class.conf $resultDir/temp/mask_00001_700K.numrttm $resultDir/temp/mask_00001_700K.rttm
rm $resultDir/temp/mask_00001_700K.numrttm
hhjo/praat2rttm.pl Databases/data_drama/ref/mask_00002_700K.TextGrid $resultDir/temp/mask_00002_700K.numrttm
hhjo/mapping_class.pl conf/class.conf $resultDir/temp/mask_00002_700K.numrttm $resultDir/temp/mask_00002_700K.rttm
rm $resultDir/temp/mask_00002_700K.numrttm
hhjo/praat2rttm.pl Databases/data_drama/ref/mask_00003_700K.TextGrid $resultDir/temp/mask_00003_700K.numrttm
hhjo/mapping_class.pl conf/class.conf $resultDir/temp/mask_00003_700K.numrttm $resultDir/temp/mask_00003_700K.rttm
rm $resultDir/temp/mask_00003_700K.numrttm

# concatenate
cat $resultDir/temp/mask_00001_700K.rttm >> $resultDir/rttm/ref_combined.rttm
cat $resultDir/temp/mask_00002_700K.rttm >> $resultDir/rttm/ref_combined.rttm
cat $resultDir/temp/mask_00003_700K.rttm >> $resultDir/rttm/ref_combined.rttm


## SER
if [ ! -e $resultDir/SER/ ];then
 mkdir -p $resultDir/SER/log/
fi
perl hhjo/md-eval-v21.pl -ac -c $ser_segment_margin -r $resultDir/rttm/ref_combined.rttm -s $resultDir/rttm/sys_combined.rttm 
mv result.txt $resultDir/SER/result.txt
END





