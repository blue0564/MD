#!/usr/bin/env perl

if ($#ARGV == -1){
  die "sys_duration.pl, no input file\n";
}

#$segment=$ARGV[0];
$classification=$ARGV[0];
$outfile=$ARGV[1];
$window_size=$ARGV[2];
$shift_size=$ARGV[3];

#open(SEG, "<$segment") || die "Error!\n";
open(CLASSIFICATION, "<$classification") || die "sys_duration.pl, input Error!\n";
open(OUTPUT, ">$outfile") || die "sys_duration.pl, ouput Error!\n";

#@seg_begin = <SEG>;
@cl_label = <CLASSIFICATION>;

$i=0;
foreach $line (@cl_label) {
  @label = $line =~ /\d{1}/g;
#  @fn = $line =~ /^([a-zA-Z][0-9a-zA-Z]{2,8})/;
  @fn = $line =~ /^(\w+)\s+/;
  $file_name[$i]="$fn[0]";
  $frame_num[$i]=$#label-11;
  $l=0;
  while($l<$frame_num[$i]){
    $frame_label[$i][$l]=$label[$l+12];
    $l++;
  }
  $i++;
}

#$j=0;
#foreach $line (@seg_begin) {
#  $e=$#cl_label+1;
#  if($j eq $e){
#      last;
#  }
#  @time = $line =~ /(\d+\.\d+)/g;
#  $begin="$time[0]";
#  $end="$time[1]";
#  $begin_time[$j]=$begin;
#  $end_time[$j]=$end;
#  $j++; 
#}

for($k=0;$k<$#cl_label+1;$k++){
  $start=0;
  $curr_State=0;
  $cur_time=0;
  $curr_frame_num=$frame_num[$k];
  $begin_ti=0;
  for($l=0;$l<$curr_frame_num;$l++){
     if($start eq 0){
        $begin_ti=0;
        $cur_time=0 + $window_size;
        $curr_State=$frame_label[$k][$l];
        $start=1;
     }
     else{
        if($curr_State eq $frame_label[$k][$l] && $l ne $last_frame){
           $cur_time = $cur_time + $shift_size;
        }
        else{
           if($curr_State eq 0){
              $frame_name = "silence";
           }
           elsif($curr_State eq 1){
              $frame_name = "noise";
           }
           elsif($curr_State eq 2){
              $frame_name = "speech";
           }
           elsif($curr_State eq 3){
              $frame_name = "music";
           }
           else{
              $frame_name = "mixed";
           }
           $last_frame=$curr_frame_num-1;
#           if($l eq $last_frame){
#              $begin = sprintf("%.3f",$begin_ti);
#              #print OUTPUT "$last_frame\n";
#              #print OUTPUT "$file_name[$k]_-$frame_name- $begin $end_time[$k]\n";
#              print OUTPUT "$file_name[$k] $frame_name $begin $end_time[$k]\n";
#           }
#           else{
       
           $end = sprintf("%.3f",$cur_time);
           $begin = sprintf("%.3f",$begin_ti);
           #print OUTPUT "$file_name[$k]_-$frame_name- $begin $end\n";
           print OUTPUT "$file_name[$k] $frame_name $begin $end\n";
           $begin_ti = $cur_time;
           $cur_time = $cur_time + $shift_size;
           $curr_State = $frame_label[$k][$l];
#           }
        }
     } 
  }
}

=t
for($k=0;$k<$#cl_label+1;$k++){
  $start=0;
  $curr_State=0;
  $cur_time=0;
  $curr_frame_num=$frame_num[$k];
  $begin_ti=0;
  for($l=0;$l<$curr_frame_num;$l++){
     if($start eq 0){
        $begin_ti=0;
        $cur_time=0 + $window_size;
        $curr_State=$frame_label[$k][$l];
        $start=1;
     }
     else{
        if($curr_State eq $frame_label[$k][$l] && $l ne $last_frame){
           $cur_time = $cur_time + $shift_size;
        }
        else{
           if($curr_State eq 0){
              $frame_name = "music";
           }
           elsif($curr_State eq 1){
              $frame_name = "speech";
           }
           else{
              $frame_name = "mixed";
           }
           $last_frame=$curr_frame_num-1;
#           if($l eq $last_frame){
#              $begin = sprintf("%.3f",$begin_ti);
#              #print OUTPUT "$last_frame\n";
#              #print OUTPUT "$file_name[$k]_-$frame_name- $begin $end_time[$k]\n";
#              print OUTPUT "$file_name[$k] $frame_name $begin $end_time[$k]\n";
#           }
#           else{
           $end = sprintf("%.3f",$cur_time);
           $begin = sprintf("%.3f",$begin_ti);
           #print OUTPUT "$file_name[$k]_-$frame_name- $begin $end\n";
           print OUTPUT "$file_name[$k] $frame_name $begin $end\n";
           $begin_ti = $cur_time;
           $cur_time = $cur_time + $shift_size;
           $curr_State = $frame_label[$k][$l];
#           }
        }
     } 
  }
}
=cut
#close(SEG);
close(CLASSIFICATION);
close(OUTPUT);
