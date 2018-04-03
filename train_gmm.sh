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

windowSize="0.125"

:<< END
## Data preparation
local/make_musan.sh /Databases/musan data
  hhjo/Supplement_database.sh /Databases/musan/PBS /Databases/musan/AudioSet/dataset \
    /Databases/musan/ESC-50/pre_audio data

## Generate mixed data 25h 36m(99200s), and mixed supplement database 25h (90000s)
#hhjo/mixed_DB.sh --total_time 99200
#hhjo/mix_PBS_AudioSet.sh --total_time 90000
hhjo/append_mixed.sh /Databases/musan/mixed data

## Train-data Mfcc feature extraction
steps/make_mfcc.sh --mfcc-config conf/mfcc_$windowSize\_$mfcc.conf --nj 4 --cmd "$train_cmd" \
 data/supplement_speech exp/make_mfcc $mfccdir
steps/make_mfcc.sh --mfcc-config conf/mfcc_$windowSize\_$mfcc.conf --nj 4 --cmd "$train_cmd" \
 data/supplement_music exp/make_mfcc $mfccdir
steps/make_mfcc.sh --mfcc-config conf/mfcc_$windowSize\_$mfcc.conf --nj 4 --cmd "$train_cmd" \
 data/supplement_noise exp/make_mfcc $mfccdir
steps/make_mfcc.sh --mfcc-config conf/mfcc_$windowSize\_$mfcc.conf --nj 4 --cmd "$train_cmd" \
 data/supplement_mixed exp/make_mfcc $mfccdir


# Check data correctly having the feature and list
utils/fix_data_dir.sh data/supplement_speech
utils/fix_data_dir.sh data/supplement_music
utils/fix_data_dir.sh data/supplement_noise
utils/fix_data_dir.sh data/supplement_mixed

## Calculate the energy-VAD of train data
sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 4 --cmd "$train_cmd" \
   data/supplement_speech exp/make_vad $vaddir
sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 4 --cmd "$train_cmd" \
   data/supplement_noise exp/make_vad $vaddir
sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 4 --cmd "$train_cmd" \
   data/supplement_music exp/make_vad $vaddir
sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 4 --cmd "$train_cmd" \
   data/supplement_mixed exp/make_vad $vaddir
END
## GMM mixture train part
sid/train_diag_ubm.sh --nj 2 --cmd "$train_cmd" --delta-window 2 \
   data/supplement_noise $gmm exp/model/diag_ubm_noise 
sid/train_diag_ubm.sh --nj 2 --cmd "$train_cmd" --delta-window 2 \
   data/supplement_speech $gmm exp/model/diag_ubm_speech 
sid/train_diag_ubm.sh --nj 2 --cmd "$train_cmd" --delta-window 2 \
   data/supplement_music $gmm exp/model/diag_ubm_music 
sid/train_diag_ubm.sh --nj 2 --cmd "$train_cmd" --delta-window 2 \
   data/supplement_mixed $gmm exp/model/diag_ubm_mixed

sid/train_full_ubm.sh --nj 4 --cmd "$train_cmd" \
   --remove-low-count-gaussians false data/supplement_noise \
   exp/model/diag_ubm_noise exp/model/full_ubm_noise 
sid/train_full_ubm.sh --nj 4 --cmd "$train_cmd" \
   --remove-low-count-gaussians false data/supplement_speech \
   exp/model/diag_ubm_speech exp/model/full_ubm_speech 
sid/train_full_ubm.sh --nj 4 --cmd "$train_cmd" \
   --remove-low-count-gaussians false data/supplement_music \
   exp/model/diag_ubm_music exp/model/full_ubm_music
sid/train_full_ubm.sh --nj 4 --cmd "$train_cmd" \
   --remove-low-count-gaussians false data/supplement_mixed \
   exp/model/diag_ubm_mixed exp/model/full_ubm_mixed



