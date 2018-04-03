#!/usr/bin/env perl

if ($#ARGV == -1){
  die "ref_trans_rttm.pl, no input file\n";
}

$ref_file=$ARGV[0];
$out_file=$ARGV[1];
$window_size=$ARGV[2];
$shift_size=$ARGV[3];

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

$curr_time=0;
$j=0;
while($n<$#data+1){
  $curr_class=$class_name[$n];
  while($curr_time < $end[$n]){
     if($curr_time==0){
       $curr_time = $curr_time + $window_size;
       if($curr_class eq "noise"){
          $frame[$j]=1;
       }
       elsif($curr_class eq "speech"){
          $frame[$j]=2;
       }
       elsif($curr_class eq "music"){
          $frame[$j]=3;
       }
       elsif($curr_class eq "mixed"){
          $frame[$j]=4;
       }
       else{
          $frame[$j]=0;
       }
       $j++;
     }
     else{
       $curr_time = $curr_time + $shift_size;
       if($curr_class eq "noise"){
          $frame[$j]=1;
       }
       elsif($curr_class eq "speech"){
          $frame[$j]=2;
       }
       elsif($curr_class eq "music"){
          $frame[$j]=3;
       }
       elsif($curr_class eq "mixed"){
          $frame[$j]=4;
       }
       else{
          $frame[$j]=0;
       }
       $j++;
     }
  }
  $n++;
}

print WFILE "$f_name  [";
for($i=0;$i<$#frame+1;$i++){
  print WFILE " $frame[$i]";
}
print WFILE " ]";

