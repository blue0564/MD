#!/usr/bin/env perl

$ref=$ARGV[0];
$sys=$ARGV[1];
$outfile=$ARGV[2];

open(REF, "<$ref") || die "sys_duration.pl, input Error!\n";
open(SYS, "<$sys") || die "sys_duration.pl, input Error!\n";
open(OUTPUT, ">$outfile") || die "sys_duration.pl, ouput Error!\n";

@refs = <REF>;
@syss = <SYS>;

$i=0;
foreach $line (@refs) {
  @label = $line =~ /\d{1}/g;
#  @fn = $line =~ /^([a-zA-Z][0-9a-zA-Z]{2,8})/;
  @fn = $line =~ /^([a-zA-Z]{2,5}\_\d{4}\_\d{4}\_\d{4})/;
  $file_name[$i]="$fn[0]";
  $frame_num_ref[$i]=$#label-11;
  $l=0;
  while($l<$frame_num_ref[$i]){
    $frame_ref[$i][$l]=$label[$l+12];
    $l++;
  }
  $i++;
}

$i=0;
foreach $line (@syss) {
  @label = $line =~ /\d{1}/g;
#  @fn = $line =~ /^([a-zA-Z][0-9a-zA-Z]{2,8})/;
  @fn = $line =~ /^([a-zA-Z]{2,5}\_\d{4}\_\d{4}\_\d{4})/;
  $file_name[$i]="$fn[0]";
  $frame_num_sys[$i]=$#label-11;
  $l=0;
  while($l<$frame_num_sys[$i]){
    $frame_sys[$i][$l]=$label[$l+12];
    $l++;
  }
  $i++;
}

for($i=0;$i<5;$i++){
   for($j=0;$j<5;$j++){
      $conf_mat[$i][$j] = 0;
   }
}
$s = $frame_num_ref[0];
print "$s\n";
for($i=0;$i<1;$i++){
   for($n=0;$n<$frame_num_ref[$i];$n++){
     if($frame_ref[$i][$n] eq $frame_sys[1][$n]){
        if($frame_ref[$i][$n] == 0){
           $conf_mat[0][0]=$conf_mat[0][0]+1;
        }
        elsif($frame_ref[$i][$n] == 1){
           $conf_mat[1][1]=$conf_mat[1][1]+1;
        }
        elsif($frame_ref[$i][$n] == 2){
           $conf_mat[2][2]=$conf_mat[2][2]+1;
        }
        elsif($frame_ref[$i][$n] == 3){
           $conf_mat[3][3]=$conf_mat[3][3]+1;
        }
        else{
           $conf_mat[4][4]=$conf_mat[4][4]+1;
        }
     }
     elsif($frame_ref[$i][$n] ne $frame_sys[1][$n]){
        if($frame_ref[$i][$n] == 0){
           if($frame_sys[$i][$n] == 1){
              $conf_mat[0][1]=$conf_mat[0][1]+1;
           }
           elsif($frame_sys[$i][$n] == 2){
              $conf_mat[0][2]=$conf_mat[0][2]+1;
           }
           elsif($frame_sys[$i][$n] == 3){
              $conf_mat[0][3]=$conf_mat[0][3]+1;
           }
           elsif($frame_sys[$i][$n] == 4){
              $conf_mat[0][4]=$conf_mat[0][4]+1;
           }
        }
        elsif($frame_ref[$i][$n] == 1){
           if($frame_sys[$i][$n] == 0){
              $conf_mat[1][0]=$conf_mat[1][0]+1;
           }
           elsif($frame_sys[$i][$n] == 2){
              $conf_mat[1][2]=$conf_mat[1][2]+1;
           }
           elsif($frame_sys[$i][$n] == 3){
              $conf_mat[1][3]=$conf_mat[1][3]+1;
           }
           elsif($frame_sys[$i][$n] == 4){
              $conf_mat[1][4]=$conf_mat[1][4]+1;
           }
        }
        elsif($frame_ref[$i][$n] == 2){
           if($frame_sys[$i][$n] == 0){
              $conf_mat[2][0]=$conf_mat[2][0]+1;
           }
           elsif($frame_sys[$i][$n] == 1){
              $conf_mat[2][1]=$conf_mat[2][1]+1;
           }
           elsif($frame_sys[$i][$n] == 3){
              $conf_mat[2][3]=$conf_mat[2][3]+1;
           }
           elsif($frame_sys[$i][$n] == 4){
              $conf_mat[2][4]=$conf_mat[2][4]+1;
           }
        }
        elsif($frame_ref[$i][$n] == 3){
           if($frame_sys[$i][$n] == 0){
              $conf_mat[3][0]=$conf_mat[3][0]+1;
           }
           elsif($frame_sys[$i][$n] == 1){
              $conf_mat[3][1]=$conf_mat[3][1]+1;
           }
           elsif($frame_sys[$i][$n] == 2){
              $conf_mat[3][2]=$conf_mat[3][2]+1;
           }
           elsif($frame_sys[$i][$n] == 4){
              $conf_mat[3][4]=$conf_mat[3][4]+1;
           }
        }
        elsif($frame_ref[$i][$n] == 4){
           if($frame_sys[$i][$n] == 0){
              $conf_mat[4][0]=$conf_mat[4][0]+1;
           }
           elsif($frame_sys[$i][$n] == 1){
              $conf_mat[4][1]=$conf_mat[4][1]+1;
           }
           elsif($frame_sys[$i][$n] == 2){
              $conf_mat[4][2]=$conf_mat[4][2]+1;
           }
           elsif($frame_sys[$i][$n] == 3){
              $conf_mat[4][3]=$conf_mat[4][3]+1;
           }
        }
     }
   }
}

print OUTPUT "ref\sys   sil         no         sp         mu         mx\n\n";
print OUTPUT "  sil    $conf_mat[0][0]        $conf_mat[0][1]         $conf_mat[0][2]          $conf_mat[0][3]         $conf_mat[0][4]\n\n";
print OUTPUT "  no     $conf_mat[1][0]        $conf_mat[1][1]         $conf_mat[1][2]         $conf_mat[1][3]        $conf_mat[1][4]\n\n";
print OUTPUT "  sp     $conf_mat[2][0]        $conf_mat[2][1]         $conf_mat[2][2]        $conf_mat[2][3]       $conf_mat[2][4]\n\n";
print OUTPUT "  mu     $conf_mat[3][0]        $conf_mat[3][1]         $conf_mat[3][2]        $conf_mat[3][3]      $conf_mat[3][4]\n\n";
print OUTPUT "  mx     $conf_mat[4][0]        $conf_mat[4][1]         $conf_mat[4][2]        $conf_mat[4][3]      $conf_mat[4][4]\n\n";

$p=0;
for($i=0;$i<5;$i++){
   for($j=0;$j<5;$j++){
      $p=$p+$conf_mat[$i][$j];
   }
}
print "$p\n";
