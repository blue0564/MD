#!/bin/bash

indir=$1
outdir=$2

cat $1 | sed -n '1p' | awk '{print $10, $11, $12}'>> $outdir

