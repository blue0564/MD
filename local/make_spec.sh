#!/bin/bash
# Copyright 2018   Byeong-Yong Jang

echo "$0 $@"  # Print the command line for logging

if [ $# -ne 4 ]; then
   echo "Usage: $0 <conf-file> <data-dir> <feat-dir> <label-str>";
   echo "e.g.: $0 conf/spec.conf data/train spec"
   exit 1;
fi

conf=$1
datadir=$2
featdir=$3
label=$4

# cheak requirement file
for f in $conf $datadir/wav.scp; do
  [[ ! -f $f ]] && echo "make_spec.sh: no such file $f" && exit 1;
done 

mkdir -p $featdir
spec_opts=$(cat conf/spec.conf | sed 's/#.*$//g' | sed ':a;N;$!ba;s/\n/ /g')
spec_opts="${spec_opts} --target-label=${label}"

echo "extract spectrogram from wave..."
echo "config : ${spec_opts}"

[[ -f $datadir/spec.scp ]] && rm -f $datadir/spec.scp

touch $datadir/spec.scp

while read line
do
  wavfile=$(echo $line | cut -d' ' -f2)
  outname=$(basename $wavfile .wav)
  outfile=${featdir}/${outname}.bin
  python tfdeep/make_cnn_egs.py ${spec_opts} $wavfile $outfile
  echo $outfile >> $datadir/spec.scp

done < $datadir/wav.scp




