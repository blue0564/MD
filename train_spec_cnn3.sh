#!/bin/bash
# Copyright 2018   Byeong-Yong Jang

. cmd.sh
. path.sh
set -e
affix=drama

exp_dir=exp/cnn_${affix}
mdldir=${exp_dir}/1
conf=conf/spec_data.conf
class_conf=conf/class_map_for_cnn_mix.conf
stage=1

[[ ! -d ${exp_dir} ]] && mkdir -p ${exp_dir}
rm -rf ${mdldir}
mkdir -p ${mdldir}

datadir=data/data_mask
decdir=$exp_dir/egs
if [ $stage -le 0 ]; then
  rm -rf $decdir
  mkdir -p $decdir

  spec_opts=$(cat $conf | sed 's/#.*$//g' | sed ':a;N;$!ba;s/\n/ /g')
  
  cat ${datadir}/wav2rttm_tr.scp |
  while read line
  do
    wavfile=$(echo $line | cut -d' ' -f1)
    rttmfile=$(echo $line | cut -d' ' -f2)
    filename=$(basename $wavfile .wav) 
    echo ${spec_opts}
    python cnn/make_cnn_egs2.py -d -v ${spec_opts} --rttm-file=${rttmfile} $wavfile  $decdir/spec_data.npy $decdir/spec_data_with_sil.pos

  done 
  grep -v 'sil' $decdir/spec_data_with_sil.pos > $decdir/spec_data.pos
fi

if [ $stage -le 1 ]; then
  cp ${class_conf} ${exp_dir}/
  python cnn/trainCNN_rand.py --num-epoch 15 --minibatch 500 \
				--keep-prob 0.6 --val-iter 100 --save-iter 1000 \
				--val-rate 1 --shuff-epoch 100 --lr 0.00001 \
				--active-function relu \
				${exp_dir}/egs/spec_data.npy ${exp_dir}/egs/spec_data.pos ${class_conf} ${mdldir} ${mdldir}/train.log

fi



