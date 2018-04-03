#!/usr/bin/env perl

if ($#ARGV == -1){
  die "praat2rttm.pl, no input file\n";
}

@classList=qw(SP MU NO SE SIL);

$ref_file=$ARGV[0];
$out_file=$ARGV[1];
open(FILE, "<$ref_file") || die "praat2rttm.pl FILE, Error! open input\n";

@data = <FILE>;
$save=0;  # SIL is ignored using '$save' variable
$cntInd=0;
$classNum=0;
$cnt=0;

foreach (@data) {
  $prepreline=$preline;
  $preline=$line;
  $line = $_;
  
  @tempClassNum = $line =~ /item \[(\d)\]\:/;
  @name = $line =~ /name = "([A-Z|a-z]+)"/;
  @intervals = $line =~ /intervals \[(\d)\]\:/;

  if($#name=="0" & !grep {$_ eq $name[0]} @classList) {
    die "praat2rttm.pl, error: not match class, modify the script\n"; }
  if($#tempClassNum=="0"){ $classNum=$tempClassNum[0]; $cntInd=0;}
  if($#name=="0" & ($name[0] eq "SIL")){ $save=0; }
  elsif($#name=="0" & ($name[0] ne "SIL")){  $save=1; }
  
  @text = $line =~ /text = "(\w+)"/;

  #if($#text=="0"){  print $text[0]."\n"; }
  
  if($#text=="0" & $save==1){ 
    @tempTmin = $prepreline =~ /xmin = (\d*\.?\d*)/;
    @tempTmax = $preline =~ /xmax = (\d*\.?\d*)/;

    $matrix[$cntInd][$classNum*3-3]=$tempTmin[0];
    $matrix[$cntInd][$classNum*3-2]=$tempTmax[0];
    $matrix[$cntInd][$classNum*3-1]=$text[0];
    $cntInd=$cntInd+1;
  }
  if($cnt==4){ @maxVal= $line =~ /xmax = (\d*\.?\d*)/; } # $maxVal[0] is last time in this file
  $cnt=$cnt+1;
}
close(FILE);

open(WFILE, ">$out_file") || die "praat2rttm.pl WFILE, Error! open output\n";
@file_name = $ref_file =~ /(\w+).TextGrid/;

$write=0;
$cur=0;
$spInd=0;
$muInd=0;
$noInd=0;
$seInd=0;
@listInd=(0, 0, 0, 0);

#@list=($matrix[$spInd][0], $matrix[$spInd][1], $matrix[$muInd][3],	$matrix[$muInd][4], $matrix[$seInd][6], $matrix[$seInd][7], $matrix[$noInd][9], $matrix[$noInd][10]);
@list=($matrix[$ind[0]][0], $matrix[$ind[0]][1], $matrix[$ind[1]][3],	$matrix[$ind[1]][4], $matrix[$ind[2]][6], $matrix[$ind[2]][7], $matrix[$ind[3]][9], $matrix[$ind[3]][10]);
#foreach((0...$#list)){ if($list[$_]==0){$list[$_]=0.00001;} };
#@list=(29, 30, 12, 13, 12, 13, 58, 63);
#$cur=12;
#$list[0]=();
#$list[1]="";
#if($list[0]==""){$list[0]=$maxVal[0]+1;};
#print "empty size is ".$list[0]==""."\n";
#print "starting list variation \n";
#print $_."\n" foreach(@list);
#print "======================\n";

$cnt=0;
$mean=0;
while($cur<$maxVal[0] & $mean<$maxVal[0]+1){
#while($cnt<1){
#print "cnt is ".$cnt."\n";
@a=searchInterval(@list,$cur);
#print "cur is ".$cur."\n";
#print "class is ".$class."\n";
$cnt=$cnt+1;

# rttm format
$begin_time=$a[0];
$dur=$a[1];
$class=$a[2];
$result="SPEAKER $file_name[0] 1 $begin_time $dur <NA> <NA> $class <NA> <NA>\n";

print WFILE "$result";

# updating list
@ind=();
@checkList=();
@odd=();
@odd=oddGenerater($#list);
foreach(@odd){
  $i=$_;
  if($list[$i] eq inf){ push(@ind,$i) }
}

push(@checkList,$list[$_]) foreach(@ind);
#print $_."\n" foreach(@checkList);
#print $_."\n" foreach(@ind);
for($i=0;$i<=$#ind;$i++){ 
  if($checkList[$i] eq inf){ 
    $changeClass=int($ind[$i]/2);
    $listInd[$changeClass]=$listInd[$changeClass]+1;
    $list[$changeClass*2]=$matrix[$listInd[$changeClass]][$changeClass*3];
    $list[$changeClass*2+1]=$matrix[$listInd[$changeClass]][$changeClass*3+1];
    if($list[$changeClass*2]==""){$list[$changeClass*2]=$maxVal[0]+1;};
    if($list[$changeClass*2+1]==""){$list[$changeClass*2+1]=$maxVal[0]+1;};
  }
}

#check average
$sum=0;
foreach(@list){ if($_ ne inf){$sum=$sum+$_;}; };
#print "list size is ".$#list."\n";
$mean=$sum/($#list+1);
#print "average is ".$mean."\n";


#updatingList(@listInd,@list);
#print "updating list variation at ".$cnt."\n";
#print "----------------------\n";
#print $_."\n" foreach(@list);
#print $_."\n" foreach(@listInd);
#print "======================\n";
}
close(WFILE);

############################## sub-function ##############################
sub getMin{
  my $min=$_[0];
  my $minPos=0;
  for (my $i=1; $i <= $#_; $i++){
    if($_[$i]<$min){$min=$_[$i]; $minPos=$i;}
  }
  return $min,$minPos;
}
sub getMax{
  my $max=$_[0];
  my $maxPos=0;
  for (my $i=1; $i <= $#_; $i++){
    if($_[$i]>$max){$max=$_[$i]; $maxPos=$i;}
  }
  return $max,$maxPos;
}

sub evenGenerater{
  $num=$_[0];
  my @even;
  for($i=0;$i<=$num;$i++){
    if($i%2==0){ push(@even,$i);}
  }
  return @even;
}

sub oddGenerater{
  $num=$_[0];
  my @odd;
  for($i=0;$i<=$num;$i++){
    if($i%2==1){ push(@odd,$i);}
  }
  return @odd;
}

sub decisionClass{
  @list=@_;
  $class=();
  @checkList=();
  @ind=();
  #print "dicisionClass sub funtion\n";
  #print "stats is ".$preState."\n";
  #print "000000000000000000000000000\n";
  @even=();
  @even=evenGenerater($#list);
  foreach(@even){
    $i=$_;
    if($list[$i] eq inf){ push(@ind,$i) }
  }
  #print "ind is \n";
  #print $_,"\n" foreach(@ind);

  #print "checkList is \n";
  #print $_,"\n" foreach(@checkList);
  #print "max is ".$max[0]."\n";

  #print "min is ".$max[0]."\n";
  $class=2**int($_/2)|$class foreach(@ind);
  #print "class is ".$class."\n";

  return $class;
}
  

sub searchInterval{
  @list=@_;
  $cur=pop(@list);
  $write=0;
  @time=();

  #print $cur."\n";
  #print $_,"\n" foreach(@list);
  for($i=0;$i<=$#list;$i++){ 
    if($list[$i] eq inf){  $list[$i]=$cur; }
  }

  #print "in searchInterval sub function\n";
  #print "change inf -> cur time\n";
  #print $_,"\n" foreach(@list);
  #print "++++++++++++++++++++++\n";

  @min=getMin(@list); 
  if($min[0]<$cur){ $list[$min[1]]=$cur;}
  elsif($min[0]>$cur){ $cur=$list[$min[1]];}
  #print $#list."\n";
  #print $_,"\n" foreach(@list);

  $stop=0;
  while($stop==0){
    @min=getMin(@list);
    $time[$write]=$min[0];
    # if min position is odd number, change that value to inf
    @even=();
    @even=evenGenerater($#list);
    if(grep {$_ eq $min[1]} @even){ $list[$min[1]]=inf;};
    #print "min value is ".$min[1]."\n";
    
     #print "write variation is ".$write."\n";    
    # write
    if($time[0] ne $time[1]){ $write=$write+1;}

    #print "state variation is ".$state[0]." ".$state[1]."\n";
    #print "time variation is ". $time[0]." ".$time[1]."\n";
    #print $_,"\n" foreach(@list);
    #print "++++++++++++++++++++++\n";

    # para update & class
    if($write>1){    
      $list[$min[1]]=$time[1];
      $class=decisionClass(@list);
      $cur=$time[1]; $dur=$time[1]-$time[0]; $begin_time=$time[0];
      $stop=1; 
    }
  }
  # check existing equal last value    
  foreach(@list){if($_==$time[1]){ $_=inf;}};
  #print "++++++++++++++++++++++\n";
  #print $_,"\n" foreach(@list);
  #print "++++++++++++++++++++++\n";

  return $begin_time, $dur, $class;
}

