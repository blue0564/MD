#!/bin/bash
# Copyright 2015   David Snyder
# Apache 2.0.
#

. cmd.sh
. path.sh
set -e
mfccdir=`pwd`/mfcc
vaddir=`pwd`/vad
resultDir='pwd'/Result

mfcc="20"
gmm="64"
dataType="drama"

#vad_energys="5.5"
frame_size="47"
ser_segment_margin=0.05

windowSize="0.125"

<< 'END'
## Data preparation
#local/make_musan.sh /Databases/musan data

## Generate mixed data 25h 36m(99200s)
#hhjo/mixed_DB.sh --total_time 99200
#hhjo/append_mixed.sh /home/hhjo/bn_music_speech_test/v1/Database/musan data
#hhjo/data_bn.sh ./Databases/data_drama data/data_drama


## Train-data Mfcc feature extraction
steps/make_mfcc.sh --mfcc-config conf/mfcc_$windowSize\_$mfcc.conf --nj 2 --cmd "$train_cmd" \
 data/musan_speech exp/make_mfcc $mfccdir
steps/make_mfcc.sh --mfcc-config conf/mfcc_$windowSize\_$mfcc.conf --nj 2 --cmd "$train_cmd" \
 data/musan_music exp/make_mfcc $mfccdir
steps/make_mfcc.sh --mfcc-config conf/mfcc_$windowSize\_$mfcc.conf --nj 2 --cmd "$train_cmd" \
 data/musan_noise exp/make_mfcc $mfccdir
steps/make_mfcc.sh --mfcc-config conf/mfcc_$windowSize\_$mfcc.conf --nj 2 --cmd "$train_cmd" \
 data/musan_mixed exp/make_mfcc $mfccdir

# Check data correctly having the feature and list
utils/fix_data_dir.sh data/musan_speech
utils/fix_data_dir.sh data/musan_music
utils/fix_data_dir.sh data/musan_noise
utils/fix_data_dir.sh data/musan_mixed


## Test-data MFCC feature extraction
#steps/make_mfcc.sh --mfcc-config conf/mfcc_$windowSize\_$mfcc.conf --nj 1 --cmd "$train_cmd" \
#data/data_$dataType exp/make_mfcc $mfccdir
#utils/fix_data_dir.sh data/data_$dataType


## Calculate the energy-VAD of train data
sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 2 --cmd "$train_cmd" \
   data/musan_speech exp/make_vad $vaddir
sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 2 --cmd "$train_cmd" \
   data/musan_noise exp/make_vad $vaddir
sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 2 --cmd "$train_cmd" \
   data/musan_music exp/make_vad $vaddir
sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 2 --cmd "$train_cmd" \
   data/musan_mixed exp/make_vad $vaddir
END
## Calculate the energy-VAD of test data
sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 1 --cmd "$train_cmd" \
   data/data_$dataType exp/make_vad $vaddir
<< END

## 13,20 Mfcc
## 8,16,32,64 GMM mixture train part
sid/train_diag_ubm.sh --nj 2 --cmd "$train_cmd" --delta-window 2 \
   data/musan_noise $gmm exp/model/diag_ubm_noise 
sid/train_diag_ubm.sh --nj 2 --cmd "$train_cmd" --delta-window 2 \
   data/musan_speech $gmm exp/model/diag_ubm_speech 
sid/train_diag_ubm.sh --nj 2 --cmd "$train_cmd" --delta-window 2 \
   data/musan_music $gmm exp/model/diag_ubm_music 
sid/train_diag_ubm.sh --nj 2 --cmd "$train_cmd" --delta-window 2 \
   data/musan_mixed $gmm exp/model/diag_ubm_mixed

sid/train_full_ubm.sh --nj 2 --cmd "$train_cmd" \
   --remove-low-count-gaussians false data/musan_noise \
   exp/model/diag_ubm_noise exp/model/full_ubm_noise 
sid/train_full_ubm.sh --nj 2 --cmd "$train_cmd" \
   --remove-low-count-gaussians false data/musan_speech \
   exp/model/diag_ubm_speech exp/model/full_ubm_speech 
sid/train_full_ubm.sh --nj 2 --cmd "$train_cmd" \
   --remove-low-count-gaussians false data/musan_music \
   exp/model/diag_ubm_music exp/model/full_ubm_music
sid/train_full_ubm.sh --nj 2 --cmd "$train_cmd" \
   --remove-low-count-gaussians false data/musan_mixed \
   exp/model/diag_ubm_mixed exp/model/full_ubm_mixed

END
## 13,20 Mfcc
## 8,16,32,64 GMM log likelihood
sid/compute_vad_decision_gmm.sh --nj 1 --cmd "$train_cmd" \
 --merge-map-config conf/merge_vad_map.txt --use-energy-vad true \
 data/data_$dataType exp/model/full_ubm_noise/ \
 exp/model/full_ubm_speech/ exp/model/full_ubm_music/ \
 exp/model/full_ubm_mixed/ \
 exp/vad_gmm exp/vad_gmm


# transrate ark to txt
copy-vector ark:exp/vad_gmm/vad_merged_data_$dataType.1.ark ark,t:$resultDir/data_$dataType.result
copy-vector ark:exp/vad_gmm/vad_merged_data_$dataType.1.ark ark,t:exp/vad_gmm/data_$dataType.result
<< 'END'
## convert reference file from praat format to rttm format
if [ -f Database/data_$dataType/ref/ref_$dataType.rttm ];then
 rm Database/data_$dataType/ref/ref_$dataType.rttm
fi

if [-f $resultDir];then
 mkdir -p $resultDir
fi

hhjo/praat2rttm.pl Database/data_drama/ref/mask_00001_700K.TextGrid $resultDir/mask_00001_700K.numrttm
hhjo/mapping_class.pl conf/class.conf Database/data_drama/ref/mask_0002_700K.rttm Database/data_drama/ref/ref_drama.rttm
hhjo/praat2rttm.pl Database/data_drama/ref/mask_0000_0000_0001.TextGrid Database/data_drama/ref/mask_0000_0000_0001.rttm
hhjo/mapping_class.pl conf/class.conf Database/data_drama/ref/mask_0000_0000_0001.rttm Database/data_drama/ref/ref_drama.rttm
hhjo/praat2rttm.pl Database/data_drama/ref/mask_0000_0000_0001.TextGrid Database/data_drama/ref/mask_0000_0000_0001.rttm
hhjo/mapping_class.pl conf/class.conf Database/data_drama/ref/mask_0000_0000_0001.rttm Database/data_drama/ref/ref_drama.rttm

## SER Evaluation process
## (ML method classification and segmentation)
if [ -f SER_RESULT/ser_$dataType.txt ];then
   rm SER_RESULT/ser_$dataType.txt
fi
if [ -f exp_$mfcc/$gmm/SER_$dataType/log/ser_frame_graph.txt ];then
   rm exp_$mfcc/$gmm/SER_$dataType/log/ser_frame_graph.txt

##transform ark to txt
hhjo/copy-vector-frame.sh exp_$mfcc/$gmm/vad_gmm $dataType

mkdir -p exp_$mfcc/$gmm/SER_$dataType

## vad_merged (sil=0, noise=1, speech=2, music=3, mix=4)
if [ $windowSize == 0.025 ];then
  shift_size=0.01
elif [ $windowSize == 0.125 ];then
  shift_size=0.05   
else
  shift_size=0.1
fi
hhjo/smoothing.pl exp/vad_gmm/vad_merged_data_$dataType.1.txt \
  exp/SER_$dataType/merged_smoothing.txt $frame_size
hhjo/sys_duration.pl exp/SER_$dataType/merged_smoothing.txt \
  exp/SER_$dataType/sysout.txt $windowSize $shift_size
hhjo/sys_duration_nosil.pl exp/SER_$dataType/sysout.txt \
  exp/SER_$dataType/sysout_nosil.txt
hhjo/ref_trans_rttm.pl exp/SER_$dataType/sysout_nosil.txt \
  exp/SER_$dataType/sys_$dataType.rttm

## SERt
mkdir -p exp_$mfcc/$gmm/SER_$dataType/log
hhjo/md-eval-v21.pl -ac -c $ser_segment_margin -r Database/data_$dataType/ref/ref_$dataType.rttm \
  -s exp/SER_$dataType/sys_$dataType.rttm 

mkdir -p SER_RESULT
cat exp/SER_$dataType/log/ser.txt | sed -n '1p' >> SER_RESULT/ser_$dataType.txt

hhjo/ser_frame_graph.sh exp_$mfcc/$gmm/SER_$dataType/log/ser.txt exp_$mfcc/$gmm/SER_$dataType/log/ser_frame_graph.txt



<< 'END'
for windowSize in $windowSizes; do
   for mfcc in $mfccs; do
      for dataType in $dataTypes; do
         for gmm in $gmms; do
            for vad_energy in $vad_energys; do  
                if [ -f $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/$dataType/ser_$dataType.txt ];then
                   rm $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/$dataType/ser_$dataType.txt
                fi
                if [ -f $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/$dataType/ser_frame_graph.txt ];then
                   rm $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/$dataType/ser_frame_graph.txt
                fi
            done
         done
      done
   done
done

for windowSize in $windowSizes; do
   for dataType in $dataTypes; do
      for mfcc in $mfccs; do
         for gmm in $gmms; do
            for vad_energy in $vad_energys; do    
               if [ $windowSize == 0.025 ];then
                  shift_size=0.01
               elif [ $windowSize == 0.125 ];then
                  shift_size=0.05   
               else
                  shift_size=0.1
               fi
               ##transform ark to txt
               hhjo/copy-vector-frame.sh $windowSize/exp_$mfcc/$gmm/"$vad_energy"_vad_gmm_$dataType $dataType
  
               mkdir -p $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/SER_$dataType

               ## vad_merged (sil=0, noise=1, speech=2, music=3, mix=4)

               #hhjo/smoothing.pl $windowSize/exp_$mfcc/$gmm/"$vad_energy"_vad_gmm_$dataType/vad_merged_data_$dataType.1.txt \
               #   $windowSize/exp_$mfcc/SER_RESULT/vad_$vad_energy/SER_$dataType/merged_smoothing.txt $frame_size
               #hhjo/sys_duration.pl $windowSize/exp_$mfcc/SER_RESULT/vad_$vad_energy/SER_$dataType/merged_smoothing.txt \
               #   $windowSize/exp_$mfcc/SER_RESULT/vad_$vad_energy/SER_$dataType/sysout.txt $win_size $shift_size

               hhjo/sys_duration.pl $windowSize/exp_$mfcc/$gmm/"$vad_energy"_vad_gmm_$dataType/vad_merged_data_$dataType.1.txt \
                  $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/SER_$dataType/sysout.txt $windowSize $shift_size

               hhjo/sys_duration_nosil.pl $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/SER_$dataType/sysout.txt \
                  $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/SER_$dataType/sysout_nosil.txt
               hhjo/ref_trans_rttm.pl $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/SER_$dataType/sysout_nosil.txt \
                  $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/SER_$dataType/sys_$dataType.rttm

               ## SER
               mkdir -p $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/SER_$dataType/log
               hhjo/md-eval-v21.pl -ac -c $ser_segment_margin -r Database/data_$dataType/ref/ref_$dataType.rttm \
                  -s $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/SER_$dataType/sys_$dataType.rttm 
       
               cat $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/SER_$dataType/log/ser.txt | sed -n '1p' >> $windowSize/exp_$mfcc/$gmm/SER_RESULT/vad_$vad_energy/SER_$dataType/ser_$dataType.txt

               #hhjo/ser_frame_graph.sh exp_$mfcc/$gmm/SER_$dataType/log/ser.txt exp_$mfcc/$gmm/SER_$dataType/log/ser_frame_graph.txt
            done
         done
      done
   done
done
END

