#!/bin/bash

# Copyright   2012  Johns Hopkins University (Author: Daniel Povey)
#             2013  Daniel Povey
#             2014  David Snyder
# Apache 2.0.

# This is a modified version of steps/train_diag_ubm.sh, specialized for
# speaker-id, that does not require to start with a trained model, that applies
# sliding-window CMVN, and that expects voice activity detection (vad.scp) in
# the data directory.  We initialize the GMM using gmm-global-init-from-feats,
# which sets the means to random data points and then does some iterations of
# E-M in memory.  After the in-memory initialization we train for a few
# iterations in parallel.


# Begin configuration section.
nj=4
cmd=run.pl
num_threads=32
delta_window=3
delta_order=2
cmn_window=300 # default 300
use_train=false
# End configuration section.

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;


if [ $# != 2 ]; then
  echo "Usage: $0  <data> <output-dir>"
  echo " e.g.: $0 data/train 1024 exp/diag_ubm"
  echo "Options: "
  echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
  echo "  --nj <num-jobs|4>                                # number of parallel jobs to run."
  echo "  --num-iters <niter|20>                           # number of iterations of parallel "
  echo "                                                   # training (default: $num_iters)"
  echo "  --stage <stage|-2>                               # stage to do partial re-run from."
  echo " --delta-window <n|3>                              # number of frames of context used to"
  echo "                                                   # calculate delta"
  echo " --delta-order <n|2>                               # number of delta features"
  echo " --use-train (true or false)			   # if use training, then true (default:false)"
  exit 1;
fi

data=$1
dir=$2


sdata=$data/split$nj
mkdir -p $dir/log
utils/split_data.sh $data $nj || exit 1;

for f in $data/feats.scp $data/vad.scp; do
   [ ! -f $f ] && echo "$0: expecting file $f to exist" && exit 1
done

delta_opts="--delta-window=$delta_window --delta-order=$delta_order"
echo $delta_opts > $dir/delta_opts

# Note: there is no point subsampling all_feats, because gmm-global-init-from-feats
# effectively does subsampling itself (it keeps a random subset of the features).

if [ $use_train == true ]; then
  echo "use training feat"
  feats="ark,s,cs:add-deltas $delta_opts scp:$sdata/JOB/feats.scp ark:- | apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=$cmn_window ark:- ark:- | select-voiced-frames ark:- scp,s,cs:$sdata/JOB/vad.scp ark:- |" # subsample-feats --n=$subsample ark:- ark:- |"
else
  feats="ark,s,cs:add-deltas $delta_opts scp:$sdata/JOB/feats.scp ark:- | apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=$cmn_window ark:- ark:- |"
fi

echo $feats > $dir/feats.info

$cmd JOB=1:$nj $dir/log/cpfeat.JOB.log \
  copy-feats "$feats" ark,scp:$dir/JOB.ark,$dir/JOB.scp || exit 1;


exit 0;
