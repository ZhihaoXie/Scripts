#!/usr/bin/perl
use Getopt::Long;

GetOptions (\%opt,"bed:s","gff:s","rpkm:s","project:s","help");


my $help=<<USAGE;
Relation of distance from nearest TE and Expression level for gene in one species.
-bed: BED format gene annotation file, generate by GFF2BED.pl from GFF3 format gene annotation.
-gff: BED format TE annotation file, should be contain only TE class that interested to calculate correlation.
-rpkm: gene expression data.
Gene	RPKM
OBR_GLEAN_10017382	64.3014830721204
OBR_GLEAN_10011719	78.1501432555481
OBR_GLEAN_10007059	24.7132214455825
-project: project name.

Run: perl $0 -bed FF.mRNA.bed -gff ../input/FF.repeat.gff -rpkm ../input/FF.shoot.rpkm -project FF
 
USAGE


if ($opt{help} or keys %opt < 1){
    print "$help\n";
    exit();
}
my $BEDtools="/home/jfchen/FFproject/tools/BEDTools/bin";
my $refrpkm=rpkmexpr($opt{rpkm});
system("$BEDtools/closestBed -a $opt{bed} -b $opt{gff} > $opt{project}.closestBED");
my $refBED=closestBED("$opt{project}.closestBED");
`rm *.closestBED`;
open OUT, ">$opt{project}.4r" or die "$!";
foreach(keys %$refBED){
    $rpkm= $refrpkm->{$_} ? $refrpkm->{$_} : N
    print "$_\t$refrpkm->{$_}\t$refBED->{$_}\n";

}
close OUT;

my $kb=2*$opt{windows}/1000;

open OUT, ">$opt{project}.r" or die "$!"; 
print OUT <<"END.";
read.table("$opt{project}.4r") -> x
z <- data.frame(x[,2],x[,3])
pdf("$opt{project}.pdf")
plot(x[,2]~x[,3],ylim=c(0,400),ylab="Expression (RPKM)",xlab="TE/$kb kb",data=z)
abline(lm(x[,2]~x[,3],data=z))
dev.off()
END.
close OUT;

system ("cat $opt{project}.r | R --vanilla --slave");
################################################
sub closestBED
{
#### get the distance from gene to nearest TE 
my ($file)=@_;
my %hash;
open IN, "$file" or die "$!";
while(<IN>){
    chomp $_;
    next if ($_ eq "");
    my @unit=split("\t",$_);
    my $distance;
    if ($unit[9] > $unit[2]){
       $distance=$unit[9]-$unit[2]+1;
    }elsif($unit[9] < $unit[1]){
       $distance=$unit[1]-$unit[9]+1;
    }else{
       $distance=0;
    }
    $hash{$unit[3]}=$distance;
}
close IN;
return \%hash;
}



sub rpkmexpr
{
my ($file)=@_;
my %hash;
open IN, "$file" or die "$!";
while(<IN>){
    chomp $_;
    next if ($_ eq "");
    my @unit=split(" ",$_);
    if ($unit[1]=~/\-/){
       $hash{$unit[0]}="NA";
    }else{
       $hash{$unit[0]}=$unit[1];
    }
}
close IN;
return \%hash;
}




 
