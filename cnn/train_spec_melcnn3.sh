#!/bin/bash
# Copyright 2018   Byeong-Yong Jang
# train CNN model using drama database

set -e
affix=drama_6class_melcnn_test

exp_dir=exp/cnn_${affix}
mdldir=${exp_dir}/s
conf=conf/spec_data_melcnn.conf
class_conf=conf/class_map_for_cnn_mix.conf
wavdir=/home2/byjang/MD-test/wav
textdir=/home2/byjang/MD-test/annotation
stage=1

[[ ! -d ${exp_dir} ]] && mkdir -p ${exp_dir}

cp $conf $exp_dir/train_feat.conf

datadir=data/data_mask_6class
decdir=$exp_dir/egs
if [ $stage -le 0 ]; then
  rm -rf ${datadir} 
  mkdir -p ${datadir}

  rttmconf=./Time2Class_test/Time2Class/class_cnn.conf
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
    perl ./Time2Class_test/Time2Class/mapping_class.pl $rttmconf $rttmfile_num $rttmfile

    echo "${line} ${rttmfile}" >> ${datadir}/wav2rttm.scp
    cat ${datadir}/wav2rttm.scp | sort | tail -n 2 > ${datadir}/wav2rttm_tr.scp


  done < ${datadir}/wav.scp


fi

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
  #grep -v 'sil' $decdir/spec_data_with_sil.pos > $decdir/spec_data.pos
  cp $decdir/spec_data_with_sil.pos $decdir/spec_data.pos
fi

if [ $stage -le 1 ]; then
  rm -rf ${mdldir}
  mkdir -p ${mdldir}
  cp ${class_conf} ${exp_dir}/
  python cnn/trainCNN_melcnn.py --num-epoch 1 --minibatch 100 \
				--keep-prob 0.6 --val-iter 100 --save-iter 10000 \
				--val-rate 1 --shuff-epoch 1 --lr 0.0001 \
				--active-function relu \
				${exp_dir}/egs/spec_data.npy ${exp_dir}/egs/spec_data.pos ${class_conf} ${mdldir} 

fi

if [ $stage -le -2 ]; then

  python cnn/trainCNN_melcnn.py --num-epoch 100 --minibatch 100 \
				--keep-prob 0.6 --val-iter 100 --save-iter 10000 \
				--val-rate 1 --shuff-epoch 1 --lr 0.00001 \
				--active-function relu \
				--mdl-dir=${exp_dir}/1 \
				${exp_dir}/egs/spec_data.npy ${exp_dir}/egs/spec_data.pos ${class_conf} ${exp_dir}/2 

fi


