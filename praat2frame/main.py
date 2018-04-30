#!/usr/bin/env python
import sys
sys.path.insert(0,'./data')	# insert folder saving 'time2class function files' to the system path
from praat2frame import Time2Class

a=Time2Class(inputTime=21,rttmFile="mask_00001_700K.rttm")
print a


