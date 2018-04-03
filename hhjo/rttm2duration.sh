#!/bin/bash

cat Database/data_bn/ref/ref_bn.rttm | awk '{if($8 == SP){s=s+$5;}else if($8 == NO){n=n+$5;}else if($8 == MU){m=m+$5;}else{mx=mx+$5;} print n, s, m, mx}' > Database/data_bn/ref/c.txt
