#!/usr/bin/env perl

if ($#ARGV == -1){
  die "ref_trans_rttm.pl, no input file\n";
}

$window_size=0.025;
$shift_size=0.01;

$ref_file=$ARGV[0];
$out_file=$ARGV[1];
open(FILE, "<$ref_file") || die ".pl, Error! open input\n";
open(WFILE, ">$out_file") || die ".pl, Error! open output\n";

@data = <FILE>;

$i=0;
foreach (@data) {
  $line = $_;
  @file_name = $line =~ /^([a-zA-Z]{2,5}\_\d{4}\_\d{4}\_\d{4})/;
  @class = $line =~ /([a-z]{5,6})/;
  @time = $line =~ /(\d+\.\d+)/g;
  $begin_time[$i]= "$time[0]";
  $end[$i]= "$time[1]";
  $class_name[$i] = $class[0];
  $f_name=$file_name[0];
  $i++;
}

$n=0;
while($n<$#data+1){
  if($n eq 0){
     print WFILE "$f_name $class_name[$n] $begin_time[$n] $end[$n]\n";
  }
  else{
     $prev_time=$n-1;
     if(($begin_time[$n]-$end[$prev_time]) gt 0.2){
        print WFILE "$f_name silence $end[$prev_time] $begin_time[$n]\n";
     }
     print WFILE "$f_name $class_name[$n] $begin_time[$n] $end[$n]\n";
  }
  $n++;
}


