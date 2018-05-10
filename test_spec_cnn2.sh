#!/bin/bash
# Copyright 2015   David Snyder
# Apache 2.0.
#

#. cmd.sh
#. path.sh
set -e

expdir=exp/cnn_full_data
dnnmdl=exp/cnn_full_data/1
stage=-1
nj=1

wavdir=/Databases/MusicDetection/MD-test/wav
textdir=/Databases/MusicDetection/MD-test/annotation
conf=conf/spec_data.conf  


datadir=`pwd`/data/data_mask
curdir=`pwd`
if [ $stage -le -1 ]; then
  rm -rf ${datadir} 
  mkdir -p ${datadir}

  conf=./Time2Class_test/Time2Class/class_cnn.conf
  find ${wavdir}/ -iname "*.wav" | sort > ${datadir}/wav.scp

  touch ${datadir}/wav2text.scp ${datadir}/wav2rttm.scp
  while read line
  do
    filename=$(basename $line .wav)
    textfile=${textdir}/${filename}.TextGrid
    echo "${line} ${textfile}" >> ${datadir}/wav2text.scp

    rttmfile_num=${datadir}/${filename}.rttm.num
    rttmfile=${datadir}/${filename}.rttm
    perl ./Time2Class_test/Time2Class/praat2rttm.pl "$textfile" "$rttmfile_num"
    perl ./Time2Class_test/Time2Class/mapping_class.pl $conf $rttmfile_num $rttmfile

    echo "${line} ${rttmfile}" >> ${datadir}/wav2rttm.scp


  done < ${datadir}/wav.scp


fi

decdir=$expdir/decode_mask
if [ $stage -le -2 ]; then
  rm -rf $decdir
  mkdir -p $decdir

  spec_opts=$(cat $conf | sed 's/#.*$//g' | sed ':a;N;$!ba;s/\n/ /g')
  
  cat ${datadir}/wav2rttm.scp | head -n 1 |
  while read line
  do
    wavfile=$(echo $line | cut -d' ' -f1)
    rttmfile=$(echo $line | cut -d' ' -f2)
    filename=$(basename $wavfile .wav) 
    echo ${spec_opts}
    python tfdeep/make_spec_rttm.py ${spec_opts} $wavfile $rttmfile $decdir/${filename}.spec $decdir/${filename}.lab


  done 



fi

: << 'END'
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

END

