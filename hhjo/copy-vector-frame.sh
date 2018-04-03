#!/bin/bash

. path.sh

dir=$1
data=$2

copy-vector ark:$dir/full_ubm_mixed_logprob.1.ark ark,t:$dir/full_ubm_mixed_logprob.1.txt
copy-vector ark:$dir/full_ubm_speech_logprob.1.ark ark,t:$dir/full_ubm_speech_logprob.1.txt
copy-vector ark:$dir/full_ubm_music_logprob.1.ark ark,t:$dir/full_ubm_music_logprob.1.txt
copy-vector ark:$dir/full_ubm_noise_logprob.1.ark ark,t:$dir/full_ubm_noise_logprob.1.txt
copy-vector ark:$dir/vad_gmm_data_$data.1.ark ark,t:$dir/vad_gmm_data_$data.1.txt
copy-vector ark:$dir/vad_merged_data_$data.1.ark ark,t:$dir/vad_merged_data_$data.1.txt
