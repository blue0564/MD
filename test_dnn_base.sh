#!/bin/bash
# Copyright 2015   David Snyder
# Apache 2.0.
#

. cmd.sh
. path.sh
set -e
mfccdir=`pwd`/mfcc
vaddir=`pwd`/vad
#dataType="drama"
dataType="drama_ICA"
resultDir=`pwd`/Result_dnn_$dataType
serResultFolder=$resultDir/SERresult
rttmFolder=$resultDir/RTTM
annotationFolder=`pwd`/Databases/data_$dataType/Annotation

frameSize="50"
ser_segment_margin=0.05

windowSize="0.125"
mfcc_conf=conf/mfcc_0.125_20.conf

dnnmdl=exp/dnn_base/1
stage=1
nj=1

twoClassMode=1
if [ $twoClassMode -eq 1 ]; then
  serResultFolder=$resultDir/SERresult_2c
  rttmFolder=$resultDir/RTTM_2c
  annotationFolder=`pwd`/Databases/data_$dataType/Annotation_2c
fi

if [ $stage -le -1 ]; then

  hhjo/data_bn.sh ./Databases/data_$dataType data/data_$dataType

  ## Test-data MFCC feature extraction
  steps/make_mfcc.sh --mfcc-config $mfcc_conf --nj 1 --cmd "$train_cmd" \
    data/data_$dataType exp/make_mfcc $mfccdir
  utils/fix_data_dir.sh data/data_$dataType
  #hhjo/delete_vad_file.sh data/data_$dataType

  ## Calculate the energy-VAD of test data
  sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 1 --cmd "$train_cmd" \
    data/data_$dataType exp/make_vad $vaddir

fi

# Extract input features from mfcc 
if [ $stage -le 0 ]; then
  dir=exp/prepare_data_${dataType}
  rm -rf $dir
  mkdir -p $dir
#  feats="ark,s,cs:add-deltas --delta-window=2 --delta-order=2 scp:data/data_${dataType}/feats.scp ark:- | apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=300 ark:- ark:- |"

  local/extract_dnn_input.sh --nj $nj --cmd "$train_cmd" --delta-window 2 \
     data/data_${dataType} $dir

#  copy-feats "$feats" ark,scp:$dir/1.ark,$dir/1.scp


fi

# Predict probability using DNN-model
if [ $stage -le 1 ]; then
  srcdir=exp/prepare_data_${dataType}
  expdir=exp/vad_dnn
  dnnfile=$expdir/predlab_dnn.txt
  sdata=data/data_${dataType}

  rm -rf $expdir 
  mkdir $expdir
  touch $dnnfile

  copy-feats ark:$srcdir/1.ark ark,scp:$expdir/feat_${dataType}.ark,$expdir/feat_${dataType}.scp

  while read line
  do
     echo $line > $expdir/tmp.scp
     copy-feats scp:$expdir/tmp.scp ark,t:$expdir/tmp_unit.txt
     cat $expdir/tmp_unit.txt | grep -v "\[" | tr -d "[]" | sed 's#^\s*##g'> $expdir/tmp.dat
     utt_index=$(echo $line | cut -d' ' -f1)

     tfdeep/dnn_base/predDNN_base.py --checkpoint 100 --out-predlab $expdir/tmp.lab $expdir/tmp.dat $dnnmdl

     cat $expdir/tmp.lab | sed "s#^#${utt_index} [ #g"  >> $dnnfile
     echo "]" >> $dnnfile
     
  done < $expdir/feat_${dataType}.scp
  rm -f $expdir/tmp.dat $expdir/tmp.scp $expdir/tmp.lab

  copy-vector ark:$dnnfile ark,scp:$expdir/vad_dnn_${dataType}.ark,$expdir/vad_dnn_${dataType}.scp
  merge-vads --map=conf/merge_vad_map.txt scp:$sdata/vad.scp \
      scp:$expdir/vad_dnn_${dataType}.scp \
      ark,scp:$expdir/vad_dnn_${dataType}_merged.ark,$expdir/vad_dnn_${dataType}_merged.scp 


fi

## convert test result format from kaldi to rttm
# transrate ark to txt in test result
if [ ! -e $resultDir/temp/ ];then
 mkdir -p $resultDir/temp/
fi
if [ ! -e $rttmFolder ];then
 mkdir -p $rttmFolder
fi
copy-vector ark:exp/vad_dnn/vad_dnn_${dataType}_merged.ark ark,t:$resultDir/temp/data_$dataType.result
copy-vector ark:exp/vad_dnn/vad_dnn_${dataType}_merged.ark ark,t:exp/vad_dnn/data_$dataType.result


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



