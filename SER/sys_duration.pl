#!/usr/bin/env perl

if ($#ARGV == -1){
  die "sys_duration.pl, no input file\n";
}

$classification=$ARGV[0];
$outfile=$ARGV[1];
$window_size=$ARGV[2];
$shift_size=$ARGV[3];

open(CLASSIFICATION, "<$classification") || die "sys_duration.pl, input Error!\n";
open(OUTPUT, ">$outfile") || die "sys_duration.pl, ouput Error!\n";

@cl_label = <CLASSIFICATION>;

$i=0;
foreach $line (@cl_label) {
  @label = $line =~ /(\d{1}) /g;
  @fn = $line =~ /^(\w+)\s+\[/;	#fixed by hwh at 2017.11.08.1539
  $file_name[$i]="$fn[0]";
  $frame_num[$i]=$#label;
  $l=0;
  while($l<$frame_num[$i]){
    $frame_label[$i][$l]=$label[$l];
    $l++;
  }
  $i++;
}

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

       
           $end = sprintf("%.3f",$cur_time);
           $begin = sprintf("%.3f",$begin_ti);
           print OUTPUT "$file_name[$k] $frame_name $begin $end\n";
           $begin_ti = $cur_time;
           $cur_time = $cur_time + $shift_size;
           $curr_State = $frame_label[$k][$l];
        }
     } 
  }
}

close(CLASSIFICATION);
close(OUTPUT);
