#!/usr/bin/env python
#
# Copyright 2018 May 1
# WoonHaeng, Heo
#
# Input: input time, rttm file path to save
# Output: class at the input time in reference
#
# modified 2018 May 2
# if first time is bigger than 0,
# modified 2018.05.10
# add end time to time array to fix error
#

import subprocess
import sys, os

def Check_file(rttmFile):
  tempName=os.path.splitext(rttmFile)
  name=os.path.split(tempName[0])
  checkrttmFile=sys.path[0]+'/'+name[1]+tempName[1]
  if not os.path.isfile(checkrttmFile):
    praatFile = sys.path[0]+'/'+name[1] + ".TextGrid"
    numbrttm = sys.path[0]+'/'+name[1] + ".Numbrttm"
    cmd=sys.path[0]+'/'+"praat2rttm.pl"
    pipe=subprocess.Popen(["perl",cmd,praatFile,numbrttm])
    pipe.wait()
    rttmFile= sys.path[0]+'/'+ name[1] + ".rttm"
    confFile= sys.path[0]+'/'+"class.conf"
    cmd=sys.path[0]+'/'+"mapping_class.pl"
    pipe=subprocess.Popen(["perl",cmd,confFile,numbrttm,rttmFile])
    pipe.wait()
  rttmFile= sys.path[0]+'/'+ name[1] + ".rttm"
  return rttmFile

def Read_rttm(rttmFile):
  # Read rttm file
  f=open(rttmFile,"r")
  time=[];
  cla=[];
  # modified 2018.05.03
  line=f.readline()
  words_line=line.split()
  if float(words_line[3])>0:
    time.append(float(0))
    cla.append("SIL")

  time.append(float(words_line[3]))
  cla.append(words_line[7])
  ########################### -modified
  while True:
    line=f.readline()
    if not line: break
    #if cnt==1: break
    words_line=line.split()
    time.append(float(words_line[3]))
    cla.append(words_line[7])
    endTime=float(words_line[3])+float(words_line[4])
  time.append(endTime)
  f.close()
  # close rttm file
  return time, cla

def Search_class(inputTime,time,cla):
  # search the input time to match the class
  cnt=0;  outClass='out of range';
  for n in time:
    if inputTime < n:
      outClass=cla[cnt-1]
      break
    cnt=cnt+1

  return outClass

if __name__=="__main__":
  rttmFile=Check_file(rttmFile="mask_00001_700K.rttm")
  time,cla=Read_rttm(rttmFile)
  outClass=Search_class(inputTime=3460.771,time=time,cla=cla)
  print outClass

