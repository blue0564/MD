#!/bin/bash
# Copyright 2018   Byeong-Yong Jang

. cmd.sh
. path.sh
set -e
affix=base

exp_dir=exp/cnn_${affix}
nj=1
stage=0

tfdeep_dir=tfdeep
[[ ! -d $tfdeep_dir ]] && echo "ERROR : not exist tfdeep directory" && exit 1;
[[ ! -s tfdeep ]] && ln -s $tfdeep_dir tfdeep

[[ ! -d ${exp_dir} ]] && mkdir -p ${exp_dir}

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
  rm -rf $featdir
  mkdir -p $featdir
  conf=conf/spec.conf  
  local/make_spec.sh $conf data/musan_speech $featdir "speech"
  local/make_spec.sh $conf data/musan_music $featdir  "music"
  local/make_spec.sh $conf data/musan_noise $featdir  "noise"
#  local/make_spec.sh $conf data/musan $featdir
  find ${featdir} -name "*.bin" > ${exp_dir}/feats.scp

fi

if [ $stage -le 1 ]; then
  mdldir=${exp_dir}/2
  rm -rf ${mdldir}
  mkdir -p ${mdldir}
  class_conf=conf/class_map_for_cnn.conf
  python tfdeep/trainCNN_base.py --splice-size 10 --spec-stride 10 \
				--num-epoch 10 --minibatch 500 \
				--keep-prob 0.6 --val-iter 100 --save-iter 1000 \
				--val-rate 5 --shuff-epoch 100 --lr 0.0001 \
				--active-function relu \
				${exp_dir}/feats.scp ${class_conf} ${mdldir} ${mdldir}/train.log

fi


