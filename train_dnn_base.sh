#!/bin/bash
# Copyright 2018   Byeong-Yong Jang

. cmd.sh
. path.sh
set -e
mfccdir=`pwd`/mfcc
vaddir=`pwd`/vad

mfcc="20"
windowSize="0.125"

nj=1

#mfcc_conf=conf/mfcc_dnn.conf
mfcc_conf=conf/mfcc_0.125_20.conf

stage=2
pre_datadir=exp/prepare_data

tfdeep_dir=tfdeep
[[ ! -d $tfdeep_dir ]] && echo "ERROR : not exist tfdeep directory" && exit 1;
[[ ! -s tfdeep ]] && ln -s $tfdeep_dir tfdeep

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
  sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 2 --cmd "$train_cmd" \
   data/supplement_speech exp/make_vad $vaddir
  sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 2 --cmd "$train_cmd" \
   data/supplement_noise exp/make_vad $vaddir
  sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 2 --cmd "$train_cmd" \
   data/supplement_music exp/make_vad $vaddir
  sid/compute_vad_decision.sh --vad-config conf/vad.conf --nj 2 --cmd "$train_cmd" \
   data/supplement_mixed exp/make_vad $vaddir
fi

# Extract input features from mfcc 
if [ $stage -le 0 ]; then
  rm -rf exp/prepare_data
  local/extract_dnn_input.sh --nj $nj --cmd "$train_cmd" --delta-window 2 --use-train true \
     data/supplement_noise exp/prepare_data/noise 
  local/extract_dnn_input.sh --nj $nj --cmd "$train_cmd" --delta-window 2 --use-train true \
     data/supplement_speech exp/prepare_data/speech 
  local/extract_dnn_input.sh --nj $nj --cmd "$train_cmd" --delta-window 2 --use-train true \
     data/supplement_music exp/prepare_data/music 
  local/extract_dnn_input.sh --nj $nj --cmd "$train_cmd" --delta-window 2 --use-train true \
     data/supplement_mixed exp/prepare_data/mixed
fi

# Prepare data for training DNN
if [ $stage -le 1 ]; then
  # GMM output map
  # 0 noise
  # 1 speech
  # 3 music
  # 4 mixed
  # save -> exp/vad_gmm/vad_gmm_data_drama.1.ark
  # filename1 [ 0 1 1 2 3 3 2 ... 
  #                 ...          ]

  echo "Prepare data for training DNN..."

  target_list='noise speech music mixed' # correspoding label : 0 1 2 3

  rm -rf $pre_datadir/data
  for i in $(seq 1 $nj)
  do
    mkdir -p $pre_datadir/data/$i
    touch $pre_datadir/data/$i/train.dat $pre_datadir/data/$i/train.lab
    target_label=0
    for target in $target_list
    do
      echo "read target : $target, target label : $target_label"
      copy-feats ark:$pre_datadir/$target/$i.ark ark,t:$pre_datadir/data/$i/$target.ark
      cat $pre_datadir/data/$i/$target.ark | grep -v "\[" | tr -d "[]" | sed 's#^\s*##g'> $pre_datadir/data/$i/$target.dat
      cat $pre_datadir/data/$i/$target.dat | cut -d ' ' -f1 | sed "s#.*#${target_label}#g" > $pre_datadir/data/$i/$target.lab

      cat $pre_datadir/data/$i/$target.dat >> $pre_datadir/data/$i/train.dat
      cat $pre_datadir/data/$i/$target.lab >> $pre_datadir/data/$i/train.lab
      target_label=`expr $target_label + 1`
    done
  done
fi



if [ $stage -le 2 ]; then
  export LD_LIBRARY_PATH=/usr/local/cuDNN/lib64:/usr/local/cuda/lib64

  echo "Train DNN..."
  srcdir=exp/prepare_data/data
  mdl=exp/dnn_base/1
  #rm -rf exp/dnn_base
  #mkdir -p exp/dnn_basef
  # initial training
  rm -rf $mdl
  mkdir -p $mdl
  #tfdeep/dnn_base/trainDNN_base.py --input-dim 60 --num-class 4 \
#			--num-epoch 20 --minibatch 500 \
#			--valEpoch 1 --save-epoch 1 --valRate 1 \
#			$srcdir/$nj/train.dat $srcdir/$nj/train.lab exp/dnn_base/1
  cmd="tfdeep/dnn_base/trainDNN_base.py --input-dim 60 --num-class 4 --num-epoch 100 --minibatch 500 --keep-prob 0.6	--valEpoch 1 --save-epoch 1 --valRate 1 --shuff-epoch 100 --lr 0.0001 --active-function relu $srcdir/$nj/train.dat $srcdir/$nj/train.lab $mdl $mdl/trainDNN.log"
			
  echo $cmd > $mdl/trainDNN.log
  $cmd 

  # train DNN using pre-trained model
  if [ $nj -gt 1 ]; then
    for nj in $(seq 2 10)
    do

      expdir=exp/dnn_base/$nj
      prenj=`expr $nj - 1`
      premdldir=exp/dnn_base/$prenj

      rm -rf $expdir
      mkdir -p $expdir

      tfdeep/dnn_base/trainDNN.py --input-dim 60 --num-class 4 \
				--num-epoch 10 --minibatch 500 \
				--valEpoch 1 --save-epoch 5 \
				--mdl-dir $premdldir --valRate 10 \
				$srcdir/$nj/train.dat $srcdir/$nj/train.lab $expdir 
    done
  fi



fi


