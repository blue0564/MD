#!/usr/bin/env perl

if ($#ARGV == -1){
  die "frame_classification.pl, no input file\n";
}

$speech_file=$ARGV[0];
$music_file=$ARGV[1];
$mixed_file=$ARGV[2];
$noise_file=$ARGV[3];
$outfile_file=$ARGV[4];

open(SPEECH, "<$speech_file") || die "speech Error!\n";
open(MUSIC, "<$music_file") || die "music Error!\n";
open(MIX, "<$mixed_file") || die "mix Error!\n";
open(NOISE, "<$noise_file") || die "noise Error!\n";
open(WFILE, ">$outfile_file") || die "output Error!\n";

@speech = <SPEECH>;
@music = <MUSIC>;
@mix = <MIX>;
@noise = <NOISE>;

$i=0;
foreach $line (@speech) {
  @slh = $line =~ /\d{1,4}\.\d{1,4}/g;
  #@fn = $line =~ /^([a-zA-Z][0-9a-zA-Z]{2,8})/;
  @fn = $line =~ /^([a-zA-Z]{3}\_\d{4}\_\d{4}\_\d{4})/;
  $file_name[$i]="$fn[0]";
  $framen[$i]=$#slh+1;
  $l=0;
  print "$#slh\n";
  while($l<$#slh+1){
    $splh[$i][$l]=$slh[$l];
    $l++;
  }
  $i++;
}

$j=0;
foreach $line (@music) {
  @mlh = "$line" =~ /\d{1,4}\.\d{1,4}/g;
  $l=0;
  while($l<$#mlh+1){
    $mulh[$j][$l]=$mlh[$l];
    $l++;
  }
  $j++;
}

$k=0;
foreach $line (@mix) {
  @xlh = "$line" =~ /\d{1,4}\.\d{1,4}/g;
  $l=0;
  while($l<$#xlh+1){
    $mxlh[$k][$l]=$xlh[$l];
    $l++;
  }
  $k++;
}

$t=0;
foreach $line (@noise) {
  @nlh = "$line" =~ /\d{1,4}\.\d{1,4}/g;
  $l=0;
  while($l<$#nlh+1){
    $nolh[$t][$l]=$nlh[$l];
    $l++;
  }
  $t++;
}

$n=0;
while($n<$#speech+1){
  for($i=0;$i<$framen[$n];$i++){
    if($splh[$n][$i] ge $mulh[$n][$i]){
      $max=$mulh[$n][$i];
    }
    else{
      $max=$splh[$n][$i];
    }

    if($max ge $mxlh[$n][$i]){
      $max=$mxlh[$n][$i];
    }

    if($max ge $nolh[$n][$i]){
      $max=$nolh[$n][$i];
    }
    #print WFILE "$nolh[$n][$i] $splh[$n][$i] $mulh[$n][$i] $mxlh[$n][$i] $max\n";
    if($max eq $splh[$n][$i]){
      $frame_cl[$n][$i]=2;
    }
    elsif($max eq $mulh[$n][$i]){
      $frame_cl[$n][$i]=3;
    }
    elsif($max eq $nolh[$n][$i]){
      $frame_cl[$n][$i]=1;
    }
    else{
      $frame_cl[$n][$i]=4;
    }
  }
  $n++;
}

$n=0;
while($n<$#speech+1){
  print WFILE "$file_name[$n] - ";
  for($i=0;$i<$framen[$n];$i++){
    print WFILE "$frame_cl[$n][$i] ";
  }
  $n++;
  print WFILE "\n";
}

close(SPEECH);
close(MUSIC);
close(MIX);
close(NOISE);
close(WFILE);
