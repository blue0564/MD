#!/usr/bin/env perl


if ($#ARGV == -1){
  die "ref_trans_rttm.pl, no input file\n";
}

$config_file=$ARGV[0];
$ref_file=$ARGV[1];
$out_file=$ARGV[2];

open(ConfigFILE, "<$config_file") || die "ref_trans_rttm.pl, Error! open config\n";
@configData = <ConfigFILE>;
@mapping=();
foreach (@configData) {
  $line = $_;
  @ref_class = $line =~ /:(\d+)-/;
  @map_class = $line =~ /-(\w+)\//;
  #print "ref_class is ".$ref_class[0]."\n";
  #print "map_class is ".$map_class[0]."\n";
  #print "map_class size is ".$#map_class."\n";
  if($#ref_class eq 0 & $#map_class eq 0){
    push(@mapping,$map_class[0]);
  }
}
close(ConfigFILE);

#print "mapping variation is \n";
#print $_," " foreach(@mapping);
#print "\nmapping size is ".$#mapping."\n";


open(FILE, "<$ref_file") || die "ref_trans_rttm.pl, Error! open rttm\n";
open(WFILE, ">$out_file") || die "ref_trans_rttm.pl, Error! open output\n";

@data = <FILE>;
foreach (@data) {
  $line=();
  $line=$_;
  @file_name = $ref_file =~ /(\w+).rttm/;

  @ref_class = $line =~ /<NA> (\d+) <NA>/;
  #print "ref_class variation is ".$ref_class[0]."\n";
  #print $line."\n"
  $line =~ s/<NA> (\d+) <NA>/<NA> $mapping[$ref_class[0]-1] <NA>/;
  #print $line;
  print WFILE "$line";

}


close(FILE);
close(WFILE);

