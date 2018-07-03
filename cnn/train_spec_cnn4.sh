#!/bin/bash
# Copyright 2018   Byeong-Yong Jang
# train CNN model using various database

set -e
## Database location ##
speech_dir=/home2/byjang/corpus/music_speech_detection/speech/librivox_with_no
music_dir=/home2/byjang/corpus/music_speech_detection/music/library_music_with_no
noise_dir=/home2/byjang/corpus/music_speech_detection/noise/ESC-50
mixed_dir=/home2/byjang/corpus/music_speech_detection/mixed


## Setting parameter ##
affix=spec
exp_dir=exp/cnn_${affix}
mdldir=${exp_dir}/1
conf=conf/spec_data.conf
class_conf=conf/class_map_for_cnn_mix.conf
stage=0
## 

[[ ! -d ${exp_dir} ]] && mkdir -p ${exp_dir}
rm -rf ${mdldir}
mkdir -p ${mdldir}

# make spectrogram
featdir=${exp_dir}/egs

if [ $stage -le 0 ]; then
  rm -rf $featdir ${exp_dir}/feats.log
  mkdir -p $featdir
  cp ${conf} ${exp_dir}/train_feat.conf
  cnn/make_spec_data2.sh $conf ${speech_dir} $featdir/spec_data.npy $featdir/spec_data_with_sil.pos "speech" 
  cnn/make_spec_data2.sh $conf ${music_dir} $featdir/spec_data.npy $featdir/spec_data_with_sil.pos "music"
  cnn/make_spec_data2.sh $conf ${noise_dir} $featdir/spec_data.npy $featdir/spec_data_with_sil.pos "noise"
  cnn/make_spec_data2.sh $conf ${mixed_dir} $featdir/spec_data.npy $featdir/spec_data_with_sil.pos "mixed"

  #grep -v 'sil' $featdir/spec_data_with_sil.pos > $featdir/spec_data.pos
  cp $featdir/spec_data_with_sil.pos $featdir/spec_data.pos
fi

if [ $stage -le 1 ]; then
  cp ${class_conf} ${exp_dir}/
  python cnn/trainCNN_rand.py --num-epoch 100 --minibatch 100 \
				--keep-prob 0.6 --val-iter 1000 --save-iter 10000 \
				--val-rate 10 --shuff-epoch 1 --lr 0.0001 \
				--active-function relu \
				${exp_dir}/egs/spec_data.npy ${exp_dir}/egs/spec_data.pos ${class_conf} ${mdldir} 

fi



