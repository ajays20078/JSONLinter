#!/usr/bin/perl
use strict;
use JSON;
use Getopt::Long;


my $JSON_DIR;
GetOptions (
	"jsoninput=s"	=> \$JSON_DIR,
);

unless(defined $JSON_DIR)
{
	print "You need to pass --jsoninput as a argument, exiting \n";
	exit(1);
}


LintJson($JSON_DIR);





sub LintJson() {
	my $JSON_DIR=shift;

	opendir(my $dh, $JSON_DIR) || die "can't opendir $JSON_DIR: $!";
	my @files = readdir($dh);
	closedir $dh;

	foreach (@files) {
		my $file=$_;
		my $absolute_name="$JSON_DIR"."/"."$file";
		if ($file eq "." || $file eq "..") {
			next; #ignore current directory
		}
		if (-d $absolute_name){
			LintJson($absolute_name);
		}
		next if ($absolute_name !~ /\.json$/i);  # ignore files other than jsons
		if (open (my $json_str, $absolute_name))
		{
  			local $/ = undef;
			my $json = JSON->new;
			eval {
   			     my $data = $json->decode(<$json_str>);
 			};
			if($@){
				print "Failed to parse $absolute_name with the following error \n";
        			print "$@ \n";
        		}
			close($json_str);
		}
        }
	return;
}

