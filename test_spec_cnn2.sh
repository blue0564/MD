#!/bin/bash
# Copyright 2015   David Snyder
# Apache 2.0.
#

#. cmd.sh
#. path.sh
set -e

expdir=exp/cnn_full_data
dnnmdl=exp/cnn_full_data/2
stage=1
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
if [ $stage -le 0 ]; then
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
    python cnn/make_cnn_egs2.py -d ${spec_opts} --rttm-file=${rttmfile} $wavfile  $decdir/${filename}.npy $decdir/${filename}.pos


  done 
fi

if [ $stage -le 1 ]; then
  ckpt=20000
  rm -f $decdir/decode_${ckpt}.log
  class_conf=conf/class_map_for_cnn_mix.conf
  [[ ! -d ${decdir} ]] && echo "ERROR: not exist decode directory" && exit 1;
  find ${decdir} -iname "*.npy" > ${decdir}/dec_data.scp

  cat ${decdir}/dec_data.scp | head -n 1 |
  while read datfile
  do
    filename=$(basename $datfile .wav)
    posfile=$(echo ${datfile} | sed 's#\.npy#.pos#g')
    labfile=$decdir/${filename}_${ckpt}.pred_lab
    rm -f ${labfile}
    python cnn/predCNN_rand.py --checkpoint ${ckpt} --out-predlab ${labfile} ${datfile} ${posfile} ${dnnmdl} ${class_conf} ${decdir}/decode_${ckpt}.log

  done 
fi
if [ $stage -le 1 ]; then
  ckpt=30000
  rm -f $decdir/decode_${ckpt}.log
  class_conf=conf/class_map_for_cnn_mix.conf
  [[ ! -d ${decdir} ]] && echo "ERROR: not exist decode directory" && exit 1;
  find ${decdir} -iname "*.npy" > ${decdir}/dec_data.scp

  cat ${decdir}/dec_data.scp | head -n 1 |
  while read datfile
  do
    filename=$(basename $datfile .wav)
    posfile=$(echo ${datfile} | sed 's#\.npy#.pos#g')
    labfile=$decdir/${filename}_${ckpt}.pred_lab
    rm -f ${labfile}
    python cnn/predCNN_rand.py --checkpoint ${ckpt} --out-predlab ${labfile} ${datfile} ${posfile} ${dnnmdl} ${class_conf} ${decdir}/decode_${ckpt}.log

  done 
fi
if [ $stage -le 1 ]; then
  ckpt=40000
  rm -f $decdir/decode_${ckpt}.log
  class_conf=conf/class_map_for_cnn_mix.conf
  [[ ! -d ${decdir} ]] && echo "ERROR: not exist decode directory" && exit 1;
  find ${decdir} -iname "*.npy" > ${decdir}/dec_data.scp

  cat ${decdir}/dec_data.scp | head -n 1 |
  while read datfile
  do
    filename=$(basename $datfile .wav)
    posfile=$(echo ${datfile} | sed 's#\.npy#.pos#g')
    labfile=$decdir/${filename}_${ckpt}.pred_lab
    rm -f ${labfile}
    python cnn/predCNN_rand.py --checkpoint ${ckpt} --out-predlab ${labfile} ${datfile} ${posfile} ${dnnmdl} ${class_conf} ${decdir}/decode_${ckpt}.log

  done 
fi

