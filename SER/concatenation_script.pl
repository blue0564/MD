#!/usr/bin/env perl


if ($#ARGV == -1){
  die "concatenation_script.pl, no input file\n";
}

#print "ARGV size is ".$#ARGV."\n";
#print "ARGV[$#ARGV] is ".$ARGV[$#ARGV]."\n";

$out_file=$ARGV[$#ARGV];
open(WFILE, ">$out_file") || die "concatenation_script.pl, Error! open output\n";

foreach((0...$#ARGV-1)){
#foreach((0)){
  #print $_."\n";
  $ref_file=$ARGV[$_];
  #print "ref file is ".$ref_file."\n";
  open(FILE, "<$ref_file") || die "concatenation_script.pl, Error! open input\n";

  @data = <FILE>;
  foreach (@data) {
    $line = $_;
    print WFILE $line;
  }
  close(FILE)
}
close(WFILE)
