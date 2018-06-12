#!/bin/bash
# Copyright 2018 Byeong-Yong Jang

set -e

affix=drama_5class_mfccdel

expdir=exp/cnn_${affix}
dnnmdl=${expdir}/1
stage=0

wavdir=/Databases/MusicDetection/MD-test/wav
textdir=/Databases/MusicDetection/MD-test/annotation
conf=${expdir}/train_feat.conf
class_conf=${expdir}/class_map_for_cnn_mix.conf


datadir=`pwd`/data/data_mask
curdir=`pwd`
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


  done < ${datadir}/wav.scp


fi

decdir=$expdir/decode_mask
if [ $stage -le 1 ]; then
  rm -rf $decdir
  mkdir -p $decdir

  spec_opts=$(cat $conf | sed 's/#.*$//g' | sed ':a;N;$!ba;s/\n/ /g')
  
  cat ${datadir}/wav2rttm.scp |
  while read line
  do
    wavfile=$(echo $line | cut -d' ' -f1)
    rttmfile=$(echo $line | cut -d' ' -f2)
    filename=$(basename $wavfile .wav) 
    echo ${spec_opts}
    python cnn/make_cnn_egs2.py -d -v ${spec_opts} --rttm-file=${rttmfile} $wavfile  $decdir/${filename}.npy $decdir/${filename}_with_sil.pos

    #grep -v 'sil' $decdir/${filename}_with_sil.pos > $decdir/${filename}.pos
    cp $decdir/${filename}_with_sil.pos $decdir/${filename}.pos

    #python cnn/check_vad_performance.py --class-file=${class_conf} $decdir/${filename}.pos $decdir/${filename}.confmat_vad
 

  done 
fi

if [ $stage -le 2 ]; then
 # ckpt=10000
  ndata=5000
  mdlnum=$(basename $dnnmdl )
  [[ ! -d ${decdir} ]] && echo "ERROR: not exist decode directory" && exit 1;
  find ${decdir} -iname "*.npy" | sort > ${decdir}/dec_data.scp

  for ckpt in 140000 700000
  do
    cat ${decdir}/dec_data.scp | 
    while read datfile
    do
      filename=$(basename $datfile .npy)
      posfile=$(echo ${datfile} | sed 's#\.npy#.pos#g')
      labfile=$decdir/${filename}_mdl${mdlnum}_${ckpt}.pred_lab
      logfile=$decdir/${filename}_mdl${mdlnum}_${ckpt}.log
      cfmfile=$decdir/${filename}_mdl${mdlnum}_${ckpt}.confmat
      rm -f ${labfile} ${logfile} 
      python cnn/predCNN_rand.py --checkpoint=${ckpt} --out-predlab=${labfile} ${datfile} ${posfile} ${dnnmdl} ${class_conf} ${logfile}
      python cnn/make_confusion_matrix.py --class-file=${class_conf} ${labfile} ${cfmfile}

    done
  done 
fi

if [ $stage -le 2 ]; then
 # ckpt=10000
  ndata=5000
  mdlnum=$(basename $dnnmdl )
  [[ ! -d ${decdir} ]] && echo "ERROR: not exist decode directory" && exit 1;
  find ${decdir} -iname "*.npy" | sort > ${decdir}/dec_data.scp
  mkdir -p $decdir/conv_out

  for ckpt in 1 140000 700000
  do
    cat ${decdir}/dec_data.scp | 
    while read datfile
    do
      filename=$(basename $datfile .npy)
      posfile=$(echo ${datfile} | sed 's#\.npy#.pos#g')
      labfile=$decdir/${filename}_mdl${mdlnum}_${ckpt}.pred_lab
      logfile=$decdir/${filename}_mdl${mdlnum}_${ckpt}.log
      cfmfile=$decdir/${filename}_mdl${mdlnum}_${ckpt}.confmat
      convdatafile=$decdir/conv_out/${filename}_mdl${mdlnum}_${ckpt}_convout.dat
      convposfile=$decdir/conv_out/${filename}_mdl${mdlnum}_${ckpt}_convout.pos
      figfile=$decdir/conv_out/${filename}_mdl${mdlnum}_${ckpt}_convout.png
      rm -f ${convdatafile} ${convdatafile} ${figfile}
      echo "Extract CNN conv output"
      python cnn/extract_CNN_conv_output.py --checkpoint=${ckpt} ${datfile} ${posfile} ${dnnmdl} ${convdatafile} ${convposfile} ${logfile}
      echo "Plot t-SNE"
      python cnn/plot_tSNE_from_pos.py --num-data=${ndata} --figure-file=${figfile} ${convdatafile} ${convposfile}

    done
  done 
fi

