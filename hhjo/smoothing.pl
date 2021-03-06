#!/usr/bin/env perl

if ($#ARGV == -1){
  die "no input file\n";
}

$window_size=$ARGV[2];
$shift_size=1;

$classification=$ARGV[0];
$smoothing=$ARGV[1];

open(CLASSIFICATION, "<$classification") || die "smoothing.pl input Error!\n";
open(OUTPUT, ">$smoothing") || die "smoothing.pl input output Error!\n";

@classifi = <CLASSIFICATION>;

$i=0;
foreach $line (@classifi) {
  @label = $line =~ /\s(\d{1})/g;
  @fn = $line =~ /^(\w+)\s+/;
  $file_name[$i]="$fn[0]";
  #$frame_num[$i]=$#label-5;
  $frame_num[$i]=$#label-11;
  $l=0;
  while($l<$frame_num[$i]){
    #$frame_label[$i][$l]=$label[$l+6];
    $frame_label[$i][$l]=$label[$l+12];
    $l++;
  }
  $i++;
}

for($k=0;$k<$#classifi+1;$k++){
  $curr_frame_num=$frame_num[$k];
  $s= $window_size%2;
  if($s == 1){
     $g = int ($window_size/2);
  }
  else{
     $g = int ($window_size/2-1);
  }
  for($l=0;$l<$curr_frame_num;$l++){
    $sil=0;
    $n=0;
    $s=0;
    $m=0;
    $mx=0;
    $max=0;
    $curr_frame=$l;
    $p=$window_size/2;
    if($curr_frame < $p){
       for($t=$curr_frame;$t<$curr_frame+$window_size;$t++){
          if($frame_label[$k][$t] eq 0){
             $sil++;
          }
          elsif($frame_label[$k][$t] eq 1){
             $n++;
          }
          elsif($frame_label[$k][$t] eq 2){
             $s++;
          }
          elsif($frame_label[$k][$t] eq 3){
             $m++;
          }
          else{
             $mx++;
          }
       }
       if($sil>$n){
          $max=$sil;
       }
       else{
          $max=$n;
       }
       if($s>$max){
          $max=$s;
       }
       if($m>$max){
          $max=$m;
       }
       if($mx>$max){
          $max=$mx;
       }
       
       if($max eq $sil){
          $lab=0;
       }
       elsif($max eq $n){
          $lab=1;
       }
       elsif($max eq $s){
          $lab=2;
       }
       elsif($max eq $m){
          $lab=3;
       }
       else{
          $lab=4;
       } 
#       for($t=$curr_frame;$t<$curr_frame+$window_size;$t++){
#          $new_frame_label[$k][$t]=$lab;
#       }
       $new_frame_label[$k][$curr_frame]=$lab;  
    }
    elsif($curr_frame > $curr_frame_num-$g){
       for($t=$curr_frame-$window_size+1;$t<=$curr_frame;$t++){
          if($frame_label[$k][$t] eq 0){
             $sil++;
          }
          elsif($frame_label[$k][$t] eq 1){
             $n++;
          }
          elsif($frame_label[$k][$t] eq 2){
             $s++;
          }
          elsif($frame_label[$k][$t] eq 3){
             $m++;
          }
          else{
             $mx++;
          }
       }
       if($sil>$n){
          $max=$sil;
       }
       else{
          $max=$n;
       }
       if($s>$max){
          $max=$s;
       }
       if($m>$max){
          $max=$m;
       }
       if($mx>$max){
          $max=$mx;
       }
       
       if($max eq $sil){
          $lab=0;
       }
       elsif($max eq $n){
          $lab=1;
       }
       elsif($max eq $s){
          $lab=2;
       }
       elsif($max eq $m){
          $lab=3;
       }
       else{
          $lab=4;
       }
#       for($t=$curr_frame-$window_size+1;$t<=$curr_frame;$t++){
#          $new_frame_label[$k][$t]=$lab;
#       }
       $new_frame_label[$k][$curr_frame]=$lab;  
    }
    else{
       for($t=$curr_frame-$g;$t<$curr_frame+$g;$t++){
          if($frame_label[$k][$t] eq 0){
             $sil++;
          }
          elsif($frame_label[$k][$t] eq 1){
             $n++;
          }
          elsif($frame_label[$k][$t] eq 2){
             $s++;
          }
          elsif($frame_label[$k][$t] eq 3){
             $m++;
          }
          else{
             $mx++;
          }
       }
       if($sil>$n){
          $max=$sil;
       }
       else{
          $max=$n;
       }
       if($s>$max){
          $max=$s;
       }
       if($m>$max){
          $max=$m;
       }
       if($mx>$max){
          $max=$mx;
       }

       if($max eq $sil){
          $lab=0;
       }
       elsif($max eq $n){
          $lab=1;
       }
       elsif($max eq $s){
          $lab=2;
       }
       elsif($max eq $m){
          $lab=3;
       }
       else{
          $lab=4;
       }     
#       for($t=$curr_frame-$g;$t<$curr_frame+$g;$t++){
#          $new_frame_label[$k][$t]=$lab;
#       }
       $new_frame_label[$k][$curr_frame]=$lab;  
    }
  }
}

=t
for($k=0;$k<$#classifi+1;$k++){
  $prev_State=0;
  $next_state=0;
  $curr_frame_num=$frame_num[$k];
  for($l=0;$l<$curr_frame_num;$l++){
     $last_frame=$curr_frame_num-1;
     if($l == 0){
        $prev_State=$l+1;
        $next_state=$l+2;
        if($frame_label[$k][$prev_State] == $frame_label[$k][$next_state]){
           $frame_label[$k][$l]=$frame_label[$k][$l+1];
        }
        else{
           $frame_label[$k][$l]=$frame_label[$k][$l];
        }
     }
     elsif($l == $last_frame){
        $prev_State=$l-1;
        $next_state=$l-2;
        if($frame_label[$k][$prev_State] == $frame_label[$k][$next_state]){
           $frame_label[$k][$l]=$frame_label[$k][$l-1];
        }
        else{
           $frame_label[$k][$l]=$frame_label[$k][$l];
        }
     }
     else{
        $prev_State=$l-1;
        $next_state=$l+1;
        if($frame_label[$k][ $prev_State] == $frame_label[$k][$next_state]){
           $frame_label[$k][$l]=$frame_label[$k][$l-1];
        }
        else{
           $frame_label[$k][$l]=$frame_label[$k][$l];
        }
     }
  }
}
=cut
$n=0;
while($n<$#classifi+1){
  print OUTPUT "$file_name[$n]  [ ";
  for($i=0;$i<$frame_num[$n];$i++){
    print OUTPUT "$new_frame_label[$n][$i] ";
  }
  $n++;
  print OUTPUT "]\n";
}

