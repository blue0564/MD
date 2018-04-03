#!/usr/bin/env perl

if ($#ARGV == -1){
  die "sys_duration_nosil.pl, no input file ARGV num\n";
}

$duration_file=$ARGV[0];
$outfile_file=$ARGV[1];

open(DURATION, "<$duration_file") || die "sys_duration_nosil.pl input Error!\n";
open(OUTPUT, ">$outfile_file") || die "output Error!\n";

@dur=<DURATION>;

$i=0;
foreach $line (@dur) {
   @class = $line =~ /([a-z]{5,7})/;
   $classn[$i] = $class[0];
   if($classn[$i] eq "silence"){
      next;
   }
   else{
      print OUTPUT "$line";
   }
   $i++;
}

