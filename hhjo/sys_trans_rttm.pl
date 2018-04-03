#!/usr/bin/env perl

if ($#ARGV == -1){
  die "ref_trans_rttm.pl, no input file\n";
}

$ref_file=$ARGV[0];
$out_file=$ARGV[1];
open(FILE, "<$ref_file") || die "ref_trans_rttm.pl, Error! open input\n";
open(WFILE, ">$out_file") || die "ref_trans_rttm.pl, Error! open output\n";

@data = <FILE>;
foreach (@data) {
  $line = $_;
  @file_name = $line =~ /^(\w+)\s+/;
  @class = $line =~ /([a-z]{5,7})/;
  @time = $line =~ /(\d+\.\d+)/g;
  $begin_time= "$time[0]";
  $duration= "$time[1]"-"$time[0]";
  $dur = sprintf("%.3f",$duration);

  if("$class[0]" eq "speech"){
     $result="SPEAKER $file_name[0] 1 $begin_time $dur <NA> <NA> SP <NA> <NA>\n";
  }
  elsif("$class[0]" eq "music"){
     $result="SPEAKER $file_name[0] 1 $begin_time $dur <NA> <NA> MU <NA> <NA>\n";
  }
  elsif("$class[0]" eq "mixed"){
     $result="SPEAKER $file_name[0] 1 $begin_time $dur <NA> <NA> MX <NA> <NA>\n";
  }
  elsif("$class[0]" eq "noise"){
     $result="SPEAKER $file_name[0] 1 $begin_time $dur <NA> <NA> NO <NA> <NA>\n";
  }
  if("$class[0]" ne "silence"){
     print WFILE "$result";
  }
}

close(FILE);
close(WFILE);

