#!/usr/bin/env perl

$ref_file=$ARGV[0];
$out_file=$ARGV[1];
open(FILE, "<$ref_file") || die ".pl, Error! open input\n";
open(WFILE, ">$out_file") || die ".pl, Error! open output\n";

@data = <FILE>;

$i=0;
foreach (@data) {
  $line = $_;
  @file_name = $line =~ /([a-zA-Z]{2,5}\_\d{4}\_\d{4}\_\d{4})/;
  @class = $line =~ /\> ([A-Z]{2}) \</;
  @time = $line =~ /(\d+\.\d+)/g;
  $begin_time[$i]= "$time[0]";
  $dur[$i]= "$time[1]";
  $class_name[$i] = $class[0];
  $f_name=$file_name[0];
  $i++;
}

$n=0;
while($n<$#data+1){
  $end = $begin_time[$n] + $dur[$n];
  if($n eq 0){
    if($class_name[$n] eq "NO"){
     print WFILE "$f_name noise 000.000 $end\n";
    }
    elsif($class_name[$n] eq "SP"){
       print WFILE "$f_name speech 000.000 $end\n";
    }
    elsif($class_name[$n] eq "MU"){
       print WFILE "$f_name music 000.000 $end\n";
    }
    else{
       print WFILE "$f_name mixed 000.000 $end\n";
    }
  }
  else{
    if($class_name[$n] eq "NO"){
     print WFILE "$f_name noise $begin_time[$n] $end\n";
    }
    elsif($class_name[$n] eq "SP"){
       print WFILE "$f_name speech $begin_time[$n] $end\n";
    }
    elsif($class_name[$n] eq "MU"){
       print WFILE "$f_name music $begin_time[$n] $end\n";
    }
    else{
       print WFILE "$f_name mixed $begin_time[$n] $end\n";
    }
  }
  $n++;
}
