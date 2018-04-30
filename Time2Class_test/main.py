#!/usr/bin/env python
import sys
sys.path.insert(0,'./Time2Class')	# insert folder saving 'time2class function files' to the system path
import Time2Class

rttmFile=Time2Class.Check_file(rttmFile="mask_00001_700K.rttm")
time,cla=Time2Class.Read_rttm(rttmFile)
outClass=Time2Class.Search_class(inputTime=24,time=time,cla=cla)
print outClass


