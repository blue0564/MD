#!/usr/bin/env python


import os, sys

def prepare_mixed(root_dir):
  utt2spk = {}
  utt2wav = {}
  mixed_dir = os.path.join(root_dir)
  for root, dirs, files in os.walk(mixed_dir):
    for file in files:
      file_path = os.path.join(root, file)
      if file.endswith(".wav"):
        utt = str(file).replace(".wav", "")
        utt2wav[utt] = file_path
        utt2spk[utt] = utt
  utt2spk_str = ""
  utt2wav_str = ""
  for utt in utt2spk:
    utt2spk_str = utt2spk_str + utt + " " + utt2spk[utt] + "\n"
    utt2wav_str = utt2wav_str + utt + " " + utt2wav[utt] + "\n"
  return utt2spk_str, utt2wav_str

def main():
  in_dir = sys.argv[1]
  out_dir = sys.argv[2]
  utt2spk_mixed, utt2wav_mixed = prepare_mixed(in_dir)
  utt2spk = utt2spk_mixed
  utt2wav = utt2wav_mixed
  wav_fi = open(os.path.join(out_dir, "wav.scp"), 'w')
  wav_fi.write(utt2wav)
  utt2spk_fi = open(os.path.join(out_dir, "utt2spk"), 'w')
  utt2spk_fi.write(utt2spk)

if __name__=="__main__":
  main()
