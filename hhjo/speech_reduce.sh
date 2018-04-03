#!/bin/bash

total_duration=0
total_time=150000
s_num=1

. ./path.sh
. parse_options.sh || exit 1;

many=$1
dir=$2

mkdir -p $dir || exit 1;

if [ -f $dir/wav.scp ];then
  rm -f $dir/wav.scp
fi
if [ -f $dir/utt2spk ];then
  rm -f $dir/utt2spk
fi
if [ -f $dir/spk2utt ];then
  rm -f $dir/spk2utt
fi

## wav-file duration 
wav-to-duration scp:$many/wav.scp ark,t:$many/speech_duration.txt 

while [ : ]
do
   s_duration=$(cat $many/speech_duration.txt | sed -n ${s_num}p | awk '{print $2}')
   cat $many/wav.scp | sed -n ${s_num}p >> $dir/wav.scp
   cat $many/utt2spk | sed -n ${s_num}p >> $dir/utt2spk
   cat $many/spk2utt | sed -n ${s_num}p >> $dir/spk2utt
   total_duration=$(echo $total_duration+$s_duration | bc)
   total=$(echo "$total_duration > $total_time" | bc)
   #echo $total $total_duration
   if [ $total == 1 ];then
     echo "total duration : " $total_duration ", file_num : " $s_num
     break;
   fi
   s_num=$((${s_num}+1))
done

rm -r $many
