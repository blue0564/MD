#!/bin/bash

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

args=("$@")
data=${args[0]}
echo $data/vad.scp

if [ -f $data/vad.scp ]; then
  rm $data/vad.scp
  echo "remove exsisting vad.scp"
fi

exit 0;
