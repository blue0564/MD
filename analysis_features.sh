#!/bin/bash
# Copyright 2018   Byeong-Yong Jang

set -e

exp_dir=exp/anal_feat_125_diffspec
conf=conf/anal_spec.conf
stage=0

[[ ! -d ${exp_dir} ]] && mkdir -p ${exp_dir}
cp $conf ${exp_dir}/anal_spec.conf

wavdir=/Databases/MusicDetection/MD-test/wav
textdir=/Databases/MusicDetection/MD-test/annotation
datadir=${exp_dir}/drama_mask

if [ $stage -le 0 ]; then
  rm -f ${datadir}/wav2rttm.scp ${datadir}/wav2text.scp
  mkdir -p ${datadir}

  clsconf=./Time2Class_test/Time2Class/class_cnn.conf
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
    perl ./Time2Class_test/Time2Class/mapping_class.pl $clsconf $rttmfile_num $rttmfile

    echo "${line} ${rttmfile}" >> ${datadir}/wav2rttm.scp

  done < ${datadir}/wav.scp

fi

decdir=${exp_dir}/drama_mask
if [ $stage -le 1 ]; then
  spec_opts=$(cat $conf | sed 's/#.*$//g' | sed ':a;N;$!ba;s/\n/ /g')
  
  cat ${datadir}/wav2rttm.scp |
  while read line
  do
    wavfile=$(echo $line | cut -d' ' -f1)
    rttmfile=$(echo $line | cut -d' ' -f2)
    filename=$(basename $wavfile .wav) 
    echo ${spec_opts}
    python cnn/make_cnn_egs2.py -d ${spec_opts} --rttm-file=${rttmfile} $wavfile  $decdir/${filename}.npy $decdir/${filename}.pos


  done 
fi
: << 'MUS'
# make spectrogram
featdir=${exp_dir}/musan

if [ $stage -le 2 ]; then
  rm -rf $featdir ${exp_dir}/feats.log
  mkdir -p $featdir
  cnn/make_spec_data.sh $conf data/musan_speech_part $featdir/spec_data.npy $featdir/spec_data.pos "speech" 
  cnn/make_spec_data.sh $conf data/musan_music_part $featdir/spec_data.npy $featdir/spec_data.pos "music"
  cnn/make_spec_data.sh $conf data/musan_noise_part $featdir/spec_data.npy $featdir/spec_data.pos "noise"
  cnn/make_spec_data.sh $conf data/musan_mixed_part $featdir/spec_data.npy $featdir/spec_data.pos "mixed"

fi
MUS

ndata=5000
drama_dir=${exp_dir}/drama_mask
musan_dir=${exp_dir}/musan
if [ $stage -le 3 ]; then
  find ${drama_dir} -iname "*.pos" | sort > ${drama_dir}/pos.scp
  cat ${drama_dir}/pos.scp | 
  while read posfile
  do
    datfile=$(echo ${posfile} | sed 's#\.pos#.npy#g')
    figfile=$(echo ${posfile} | sed 's#\.pos#.png#g')
    python cnn/plot_tSNE_from_pos.py --num-data=${ndata} --figure-file=${figfile} $datfile $posfile
  done

  #python cnn/plot_tSNE_from_pos.py --num-data=${ndata} \
  #                                 --figure-file=${musan_dir}_time/spec_data.png \
  #                                 ${musan_dir}/spec_data.npy ${musan_dir}/spec_data.pos

fi






