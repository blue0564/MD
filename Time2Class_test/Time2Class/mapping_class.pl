#!/usr/bin/env perl


if ($#ARGV == -1){
  die "mapping_class.pl, no input file\n";
}

$config_file=$ARGV[0];
$ref_file=$ARGV[1];
$out_file=$ARGV[2];

open(ConfigFILE, "<$config_file") || die "mapping_class.pl, Error! open config\n";
@configData = <ConfigFILE>;
@mapping=();
foreach (@configData) {
  $line = $_;
  @ref_class = $line =~ /:(\d+)-/;
  @map_class = $line =~ /-(\w+)\//;
  if($#ref_class eq 0 & $#map_class eq 0){
    push(@mapping,$map_class[0]);
  }
}
close(ConfigFILE);


open(FILE, "<$ref_file") || die "mapping_class.pl, Error! open rttm\n";
open(WFILE, ">$out_file") || die "mapping_class.pl, Error! open output\n";

@data = <FILE>;
$start=0;
$preClass=0;
foreach (@data) {
  $line=();
  $line=$_;

  #@str=$line=~/\s/;
  @str=split / /,$line;
  $nowStart=$str[3]; $nowDur=$str[4];
  $nowEnd=$str[3] + $str[4];
  $nowClass=$mapping[$str[7]-1];
  $nowFile=$str[1];
  #print WFILE "$str[0] $nowFile $str[2] $nowStart $nowDur $str[5] $str[6] $nowClass $str[8] $str[9]";
  #print WFILE "preStart: $preStart, preDur: $preDur, preEnd: $preEnd, preClass: $preClass, preFile: $preFile\n";
  #print WFILE "nowStart: $nowStart, nowDur: $nowDur, nowEnd: $nowEnd, nowClass: $nowClass, nowFile: $nowFile\n";
  #$timeDiff=abs($preEnd - $nowStart)<0.002;
  #print WFILE "diff Time: $timeDiff, \n";
  #$preStart=$nowStart; $preDur=$nowDur; $preEnd=$nowEnd; $preClass=$nowClass; $preFile=$nowFile;

  if(($nowClass eq $preClass) && (abs($preEnd-$nowStart)<0.002)){
    #print WFILE "diff time is $preEnd-$nowStart\n";
    $preDur=$preDur + $nowDur; $preEnd=$nowEnd; $preFile=$nowFile;
    #print WFILE "preDur is $preDur\n";
  }elsif(($start==1) && ($preFile eq $nowFile) && ($nowClass ne $preClass) | (abs($preEnd-$nowStart)>0.002) ){
    print WFILE "$str[0] $preFile $str[2] $preStart $preDur $str[5] $str[6] $preClass $str[8] $str[9]";
    $preStart=$nowStart; $preDur=$nowDur; $preEnd=$nowEnd; $preFile=$nowFile; $preClass=$nowClass;
  }
 
  #print WFILE "$line";
  if($start==0){ $preStart=$nowStart; $preDur=$nowDur; $preEnd=$nowEnd; $preFile=$nowFile; $preClass=$nowClass; }

  $start=1;
}
print WFILE "$str[0] $preFile $str[2] $preStart $preDur $str[5] $str[6] $preClass $str[8] $str[9]";

close(FILE);
close(WFILE);

