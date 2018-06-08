#!/bin/bash
# Copyright 2018   Byeong-Yong Jang
# train CNN model using MUSAN database

. cmd.sh
. path.sh
set -e
affix=base

exp_dir=exp/cnn_${affix}
mdldir=${exp_dir}/1
conf=conf/spec_data.conf
class_conf=conf/class_map_for_cnn_mix.conf
stage=1

[[ ! -d ${exp_dir} ]] && mkdir -p ${exp_dir}
rm -rf ${mdldir}
mkdir -p ${mdldir}

# preprocessing for training vad with GMM (MUSAN)
if [ $stage -le -1 ]; then
  ## Data preparation
  local/make_musan.sh /Databases/musan data
  hhjo/Supplement_database.sh /Databases/musan/PBS /Databases/musan/AudioSet/dataset \
    /Databases/musan/ESC-50/pre_audio data

  ## Generate mixed data 25h 36m(99200s), and mixed supplement database 25h (90000s)
  #hhjo/mixed_DB.sh --total_time 99200
  #hhjo/mix_PBS_AudioSet.sh --total_time 90000
  hhjo/append_mixed.sh /Databases/musan/supplement_mixed data
fi


# make spectrogram
featdir=${exp_dir}/egs

if [ $stage -le 0 ]; then
  rm -rf $featdir ${exp_dir}/feats.log
  mkdir -p $featdir
  cp ${conf} ${exp_dir}/train_feat.conf
  cnn/make_spec_data.sh $conf data/musan_speech $featdir/spec_data.npy $featdir/spec_data_with_sil.pos "speech" 
  cnn/make_spec_data.sh $conf data/musan_music $featdir/spec_data.npy $featdir/spec_data_with_sil.pos "music"
  cnn/make_spec_data.sh $conf data/musan_noise $featdir/spec_data.npy $featdir/spec_data_with_sil.pos "noise"
  cnn/make_spec_data.sh $conf data/musan_mixed $featdir/spec_data.npy $featdir/spec_data_with_sil.pos "mixed"

  grep -v 'sil' $featdir/spec_data_with_sil.pos > $featdir/spec_data.pos
fi

if [ $stage -le 1 ]; then
  cp ${class_conf} ${exp_dir}/
  python cnn/trainCNN_rand.py --num-epoch 50 --minibatch 500 \
				--keep-prob 0.7 --val-iter 100 --save-iter 1000 \
				--val-rate 1 --shuff-epoch 100 --lr 0.0001 \
				--active-function relu \
				${exp_dir}/egs/spec_data.npy ${exp_dir}/egs/spec_data.pos ${class_conf} ${mdldir} ${mdldir}/train.log

fi



