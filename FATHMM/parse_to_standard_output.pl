#!/usr/bin/perl

use warnings;
use Getopt::Long;
use List::Util qw(sum);

my ($file_in, $numSamples, $file_out, $out_dir, $flag_debug, $flag_help);

my $help_message = "
This script parses FATHMM's output to a standard output.

Usage:
	parse_to_standard_output.pl [OPTIONS]

Options:
	--in = path to FATHMM results file *
	--samples = number of samples *
	--outDir = path to output directory *
	--debug: prints trace to STDERR
	--help : prints this message

* indicates required parameters


Version:
	1.1

Author:
	Burton Chia - chiakhb\@gis.a-star.edu.sg
	Denis Bertrandd - bertrandd\@gis.a-star.edu.sg\n";

if ( @ARGV == 0 ) {
	print $help_message;
	exit 0;
}

GetOptions(
	"in=s"      	=> \$file_in,
	"samples=i"		=> \$numSamples,
	"outDir=s"    => \$out_dir,
	"debug"       => \$flag_debug,
	"help"        => \$flag_help
) or die("Error in command line arguments.\n");

if ($flag_help) {
	print $help_message;
	exit 0;
}


if ($flag_debug) {
	print STDERR "Input parameters:\n";
	print STDERR "INPUT: $file_in\n";
	print STDERR "OUTPUT: $out_dir\n";
}

$file_out = "$out_dir/fathmm.temp";
open(OUT, ">$file_out");
open(IN, "sort -k1,1 $file_in |");
$currentGene = "";
@currentScore = ();
$currentSample = "";
$bestScore = 0;
@samples = ();
while(<IN>){
  chomp(@temp = split(/\t/, $_));
  $gene = $temp[0];
  $score = $temp[2];
  $sample = $temp[3];
  if( $gene ne $currentGene && $currentGene ne ""){	# new gene encountered
    # push previous entry to array
    push(@currentScore, $bestScore);
    push(@samples, $currentSample);

    # Print results and re-initialize variables
    print OUT $currentGene . "\t" . sum(@currentScore)/$numSamples . "\t" . join(";", @samples) . "\t" . join(";", @currentScore) . "\n";
    $currentGene = "";
    @currentScore = ();
    $currentSample = "";
    $bestScore = $score;
    @samples = ();
  }
  $currentSample = $sample if ($currentSample eq "");
  $currentGene = $gene if ($currentGene eq "");
  if( $sample ne $currentSample){	# new sample encountered
    # push previous sample to array and re-initialize variables
    push(@currentScore, $bestScore);
    push(@samples, $currentSample);
    $currentSample = $sample;
    $bestScore = 0;
  }
  $bestScore = $score if ($score < $bestScore);
}
# Print last entry
push(@currentScore, $bestScore);
push(@samples, $currentSample);
print OUT $currentGene . "\t" . sum(@currentScore)/$numSamples . "\t" . join(";", @samples) . "\t" . join(";", @currentScore) . "\n";
close(OUT);
close(IN);

$counter = 1;
$file_out = "$out_dir/fathmm.result";
open(IN, "sort -k2,2g $out_dir/fathmm.temp |");
open(OUT, ">$file_out");
print OUT "Gene_name\tSample\tRank\tScore\tInfo\tSample-specific_score\n";	# print header
while(<IN>){
  chomp(@temp = split(/\t/, $_));
  $gene = $temp[0];
  $score = $temp[1];
  $sample = $temp[2];
	$sample_specific_score = $temp[3];
  print OUT $gene . "\t" . $sample . "\t" . $counter . "\t" . $score . "\t" . "-" . "\t" . $sample_specific_score . "\n";
  $counter++;
}
close(OUT);
close(IN);
system("rm -f $out_dir/fathmm.temp") unless $flag_debug;
