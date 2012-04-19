#!/usr/bin/perl

use IO::File;
use File::Spec;
use File::Find;
use File::stat;
use Archive::Zip qw(:ERROR_CODES);
use Getopt::Std;
use Time::Local

@files = ();
%file_names = ();
%publishers = ();
%publisher_by_title = ();
%authors = ();
%titles = ();
%options=();
getopts("s:Se:Ept:Tif:F",\%options);

if (defined($options{s})) {
	($date_split_d,$date_split_m,$date_split_y) = split(/\//, $options{s});
	$date_split_d = $date_split_d;
	$date_split_m = $date_split_m -1;
	$start_date = timelocal(1,0,0,$date_split_d,$date_split_m,$date_split_y);
} else {
	$start_date = timelocal(1,0,0,1,1,1970);
}

if (defined($options{e})) {
	($date_split_d,$date_split_m,$date_split_y) = split(/\//, $options{e});
	$date_split_d = $date_split_d -1;
	$date_split_m = $date_split_m -1;
	$end_date = timelocal(0,0,0,$date_split_d,$date_split_m,$date_split_y);
} else {
	$end_date = time;
}

my $counter = 0;
my $repeat_counter = 0;
my $publisher_counter = 0;

#TROLOLOL NEED TO ADJUST THIS!

my $localdir = 'D:\Random House';
my $now = localtime time;

print "\n\n\n+------------------------------------------------------------------------------+\n";
print "|                                                                              |\n";
print "|                         STUNJELLY - PUBLISHER COUNTER                        |\n";
print "|                           ".$now."                           |\n";
print "|                                                                              |\n";
print "+------------------------------------------------------------------------------+\n\n\n";



#find(sub { print $File::Find::name, "\n" if /\.epub$/ },$localdir);
find(
sub {
	push (@files, $File::Find::name), "\n" if /\.epub$/;
	
},
$localdir);


foreach $file (@files) {
	if ($file =~ m/\/\._/) {
		#dosomething
	}
	elsif (-d $file){
		#file is a directory so skip
	}
	else {
		$file_name = ($file =~ m/\/([^\/.]*?)\./)[0];
		
		
		if ($start_date < ((stat($file))[0][9]) && $end_date > ((stat($file))[0][9])){
			if (!defined($file_names{$file_name})){
				$file_names{$file_name} = $file;
			} elsif ((stat($file))[0][9] > (stat($file_names{$file_name}))[0][9]){
				$file_names{$file_name} = $file;
				$repeat_counter++;
			}  else {
				$repeat_counter++;
			}
		$counter++; 
		}
	}
}


foreach $i (keys(%file_names)) {
	my $zip = Archive::Zip->new();
	my $zipName = $file_names{$i};
	my $status = $zip->read( $zipName );
	#die "Read of $zipName failed\n" if $status != AZ_OK;

	my $dir = 'indexing_working';

	(mkdir($dir, 0777) or die "Can't create directory $dir\: $!\n") unless -d $dir;
	for my $member ( $zip->members )
	{
	
		my $ext = ($member->fileName =~ m/([^.]+)$/)[0];
		if ($ext eq "opf"){
			($volume,$directories,$filet) = File::Spec->splitpath( $member->fileName);
			$member->extractToFileNamed("working/content.opf");
		}
	}
	
	open HTMLWTF, "<", "working/content.opf" or die $!;
	while (my $line = <HTMLWTF>) {
		
		if ($line =~ m/<dc:creator opf:role="aut">(.*?)<\/dc:creator>/i){
			$author = $1;
			$authors{$i} = $author;
		}
		
		if ($line =~ m/<dc:title>(.*?)<\/dc:title>/i){
			$title = $1;
			$titles{$i} = $title;
		}
		
		if ($line =~ m/<dc:publisher>(.*?)[\s]?(books|uk|press|group)?<\/dc:publisher>/i){
			$publisher = lc($1);
			$publisher_by_title{$i} = $publisher;
			if (!defined($publishers{$publisher})) {
				$publishers{$publisher} = 1;
			} else {
				$publishers{$publisher} = ($publishers{$publisher}+1);
			}
			$publisher_counter++;
		}
	}
}

if (defined ($options{s}) ){
print "\tStart Date:".$options{s}."\t";
	}
	else {
	
print "\tStart Date: 01/01/1970\t";	
		}
		
		if (defined ($options{e}) ){
print "\tEnd Date:".$options{e}."\n";
	}
	else {
	
print "\tEnd Date: ".$now."\n";	
		}
		
	
#print "\tStart Date:".$start_date."\t";
#print "\tEnd Date:".$end_date."\n";
print "        ------------------------------------------------------------------------\n";
print "\tEPUB files Found: ".$counter."\t";
print "\tRepeats found: ".$repeat_counter."\n";
print "\tActual books found:".($counter - $repeat_counter)."\t";
print "\tBooks with publishers:".$publisher_counter."\n\n";
print "================================================================================\n";

if (!defined($options{i})) {

	print "PUBLISHER\t\t\t\t\t";
	
	if (!defined($options{p})) {
		print "\t";
	}
	if (!defined($options{t})) {
		print "\t";
	}
	print"     #BOOKS";
	
	if (defined($options{p})) {
		print "   \%TOTAL";
	}
	if (defined($options{t})) {
		print "    £OWED";
	}
	
	print "\n================================================================================\n";
	
	foreach $j (sort keys(%publishers)) {
		$tabs = 0;
		$tabs_str = "";
		$publisher_name = uc($j);
		$publisher_name =~ s/\&AMP\;/\&/i;
		
		$publisher_len = length($publisher_name);
		if ($publisher_len < 7) {
			$tabs = 9;
		}elsif ($publisher_len < 15){
			$tabs = 8;
		}elsif ($publisher_len < 23){
			$tabs = 7;
		}elsif ($publisher_len < 31){
			$tabs = 6;
		}elsif ($publisher_len < 39){
			$tabs = 5;
		}elsif ($publisher_len < 47){
			$tabs = 4;
		}elsif ($publisher_len < 55){
			$tabs = 3;
		}elsif ($publisher_len < 63){
			$tabs = 2;
		}elsif ($publisher_len < 71){
			$tabs = 1;
		}
		if (defined($options{p})) {
			$tabs--;
		}
		if (defined($options{t})) {
			$tabs--;
		}
		for ($k=0; $k < $tabs; $k++) {
			$tabs_str .= "\t";
		}
	
		print $publisher_name.":".$tabs_str.$publishers{$j};
	
		if (defined($options{p})) {
			print "\t".int(($publishers{$j}/($counter - $repeat_counter))*100)."%";
		}
	
		if (defined($options{t})) {
			$perc = ($publishers{$j}/($counter - $repeat_counter));
			$amount = (int(($perc * $options{t})*100)/100);
			print "\t£".$amount;
		}
		print "\n";
	}
} else {
	$title_count =0;
	$spreadsheet_dump = "";
	foreach $isbn (sort keys(%file_names)) {
		if ($isbn =~ m/[^0-9]/){
			#123123
		} else {
			print $isbn." - ";
			
			
			$spreadsheet_dump .= $isbn.";";
			if (defined($titles{$isbn})) {
				print $titles{$isbn}." - ";
				$title_d = $titles{$isbn};
				$title_d =~ s/;//g;
				$spreadsheet_dump .= $title_d.";";
			}else {
				$spreadsheet_dump .= ";";
			}
			if (defined($authors{$isbn})) {
				print $authors{$isbn}." - ";
				$author_d = $authors{$isbn};
				$author_d =~ s/;//g;
				$spreadsheet_dump .= $author_d.";";
			}else {
				$spreadsheet_dump .= ";";
			}
			if (defined($publisher_by_title{$isbn})) {
				print $publisher_by_title{$isbn};
				$publisher_by_title_d = $publisher_by_title{$isbn};
				$publisher_by_title_d =~ s/;//g;
				$spreadsheet_dump .= $publisher_by_title_d.";";
			}else {
				$spreadsheet_dump .= ";";
			}
			print "\n";
			$spreadsheet_dump .="\n";
			$title_count++;
		}
	}
	print "TITLE COUNT: ".$title_count;
	
	if (defined($options{f})) {
		
		open (MYFILE, ">>".$options{f}.".csv");
		print MYFILE $spreadsheet_dump;
		close (MYFILE);
	}
}
print "\n--------------------------------------------------------------------------------\n";
print "--------------------------------------------------------------------------------\n";


