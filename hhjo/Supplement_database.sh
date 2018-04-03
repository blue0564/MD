#!/bin/bash
# Copyright 2018   Mar WoonHaneg, Heo
#
# This script increases the data quantity by adding another database.
# Another database is PBS(korean speech), Google AudioSet(music), ESC-50(noise)
# Information for database: http://www.cs.tut.fi/~heittolt/datasets#acoustic-scenes
# And then, We will train the model like DNN, GMM using increased database.
#
:<< END
pbsPath=/home/whheo/Databases/PBS
audiosetPath=/home/whheo/Databases/AudioSet/dataset
escPath=/home/whheo/Databases/ESC-50/pre_audio
END

if [ $# != 3 ]; then
   echo "Usage: $0 <PBS-DB-path> <AudioSet-DB-path> <ESC-DB-path>";
   echo "e.g.: sh $0 /Databases/PBS /Databases/ESC-50 /Databases/AudioSet/dataset"
   exit 1;
fi

pbsPath=$1
audiosetPath=$2
escPath=$3

rm -rf local/supplement.tmp
mkdir local/supplement.tmp

echo "Preparing data supplement to musan"
find $pbsPath -name '*.wav' > local/supplement.tmp/pbs.list
find $audiosetPath/eval -name '*.wav' > local/supplement.tmp/AudioSet.list
find $audiosetPath/balanced -name '*.wav' >> local/supplement.tmp/AudioSet.list
find $escPath -name '*.wav' > local/supplement.tmp/esc.list

hhjo/Add_list.sh local/supplement.tmp/pbs.list $4/musan_speech
hhjo/Add_list.sh local/supplement.tmp/AudioSet.list $4/musan_music
hhjo/Add_list.sh local/supplement.tmp/esc.list $4/musan_noise


