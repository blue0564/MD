#!/bin/bash
#
# For supplying database,
# This script is changed in 2018 Mar by WoonHaeng, Heo
# 
#


set -e
in_dir=$1
data_dir=$2

echo "Preparing ${data_dir}/musan_mixed..."
hhjo/append_mixed.py ${in_dir} ${data_dir}/musan

grep "mixed" ${data_dir}/musan/utt2spk > local/supplement.tmp/utt2spk_mixed

utils/subset_data_dir.sh --utt-list local/supplement.tmp/utt2spk_mixed \
  ${data_dir}/musan ${data_dir}/supplement_mixed

utils/fix_data_dir.sh ${data_dir}/supplement_mixed





