#!/bin/bash

. cmd.sh
. path.sh

f=$1
out=$2
cat $f | awk '{if($8 == "SP"){printf(%3f %s %3f %3f, $2, "speech", $4, $4+$5);}else if($8 == "MU"){printf(%3f %s %3f %3f, $2, "music", $4, $4+$5);}else if($8 == "NO"){printf(%3f %s %3f %3f, $2, "noise", $4, $4+$5);}else{printf(%3f %s %3f %3f, $2, "mixed", $4, $4+$5);}}' > $out

