#!/bin/bash

. ./path.sh

music_wav=/home/hhjo/bn_music_speech_test/v1/data/musan_music
speech_wav=/home/hhjo/bn_music_speech_test/v1/data/musan_speech
dir=/home/hhjo/bn_music_speech_test/v1/Database/musan/mixed
total_time=180000
reduce_music_volume=0.4
mfile=226
sfile=218
mkdir -p $dir/wav 
mkdir $dir/wav_fi 
mkdir $dir/m_down
mkdir $dir/s_down
down_music=$dir/down

. parse_options.sh || exit 1;


if [ -f $dir/min.txt ]; then
   rm $dir/min.txt
fi
if [ -f $dir/m_down/wav.scp ]; then
   rm $dir/m_down/wav.scp
fi
if [ -f $dir/s_down/wav.scp ]; then
   rm $dir/s_down/wav.scp
fi
echo "mixed music/speech processing"

##wav volume down
while read line
do
   snr=$(echo $RANDOM%10 + 5 | bc)
   name=$(echo "$line" | awk '{print $1}')
   path=$(echo "$line" | awk '{print $2}')
   sox $path $dir/m_down/$name.wav gain -n -$snr
   echo "$line" | awk '{print $1, "/home/hhjo/bn_music_speech_test/v1/Database/musan/mixed/m_down/"$1".wav"}' >> $dir/m_down/wav.scp
done < $music_wav/wav.scp

while read line
do
   snr=$(echo $RANDOM%10 + 1 | bc)
   name=$(echo "$line" | awk '{print $1}')
   path=$(echo "$line" | awk '{print $2}')
   sox $path $dir/s_down/$name.wav gain -n -$snr
   echo "$line" | awk '{print $1, "/home/hhjo/bn_music_speech_test/v1/Database/musan/mixed/s_down/"$1".wav"}' >> $dir/s_down/wav.scp
done < $speech_wav/wav.scp


## wav-file duration 
wav-to-duration scp:$dir/m_down/wav.scp ark,t:$dir/music_duration.txt
wav-to-duration scp:$dir/s_down/wav.scp ark,t:$dir/speech_duration.txt

paste $dir/m_down/wav.scp $dir/music_duration.txt | awk '{print $1, $4, $2}' > $dir/music.txt
paste $dir/s_down/wav.scp $dir/speech_duration.txt | awk '{print $1, $4, $2}' > $dir/speech.txt


## random mixed case (total 180000s -> 50h)
k=0
total_duration=0
m_num=$(echo $RANDOM%$mfile+ 1 | bc)
s_num=$(echo $RANDOM%$sfile + 1 | bc)
while [ : ]
do
  m=$(cat $dir/music.txt | sed -n ${m_num}p | awk '{print $3}')
  s=$(cat $dir/speech.txt | sed -n ${s_num}p | awk '{print $3}')
  m_duration=$(cat $dir/music.txt | sed -n ${m_num}p | awk '{print $2}')
  s_duration=$(cat $dir/speech.txt | sed -n ${s_num}p | awk '{print $2}')
  min_duration=$(echo "$m_duration $s_duration" | awk '{if($1>=$2){print $2;}else{print $1;}}')
  total_duration=$(echo $total_duration+$min_duration | bc)
  sox -m $m $s $dir/wav/mixed$k.wav
  sox $dir/wav/mixed$k.wav $dir/wav_fi/mixed$k.fi.wav trim 0 ${min_duration}
  m_num=$(echo $RANDOM%$mfile + 1 | bc)
  s_num=$(echo $RANDOM%$sfile + 1 | bc)
  total=$(echo "$total_duration > $total_time" | bc)
  echo $total $total_duration
  k=$((${k}+1))
  if [ $total == 1 ];then
    echo "total duration : " $total_duration ", file_num : " $k
    break;
  fi
done

#rm -r $dir/down
rm -r $dir/wav 
