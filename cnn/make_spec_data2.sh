#!/bin/bash
# Copyright 2018   Byeong-Yong Jang

echo "$0 $@"  # Print the command line for logging

if [ $# -ne 5 ]; then
   echo "Usage: $0 <conf-file> <wav-dir> <spec-file> <pos-file> <label-str>";
   echo "e.g.: $0 conf/spec.conf corpus/music exp/spec.npy exp/spec.pos speech"
   exit 1;
fi

conf=$1
datadir=$2
specfile=$3
posfile=$4
label=$5

# cheak requirement file
for f in $conf ; do
  [[ ! -f $f ]] && echo "make_spec_data2.sh: no such file $f" && exit 1;
done 

spec_opts=$(cat $conf | sed 's/#.*$//g' | sed ':a;N;$!ba;s/\n/ /g')
spec_opts="${spec_opts} --target-label=${label}"

echo "extract spectrogram from wave..."
echo "config : ${spec_opts}"

#[[ -f $datadir/spec.scp ]] && rm -f $datadir/spec.scp

#touch $datadir/spec.scp

find ${datadir}/ -iname '*.wav' | sort | 
while read line
do
  wavfile=${line}
  outname=$(basename "$wavfile" .wav)
  outfile=${featdir}/${outname}.bin
  echo "proc -> ${wavfile}"
  python cnn/make_cnn_egs2.py ${spec_opts} "$wavfile" "$specfile" "$posfile"
  #echo $outfile >> $datadir/spec.scp

done 




