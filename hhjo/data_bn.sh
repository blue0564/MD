#!/bin/bash

data_dir=$1
out_dir=$2

mkdir -p $out_dir

hhjo/data_bn.py $data_dir $out_dir

utils/fix_data_dir.sh $out_dir
