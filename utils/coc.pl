#!/usr/bin/perl -w
# Code Counter script, works mostly off of 'wc'

my @all_filepaths;
foreach ("../*.pl", "../lib/*.pm", "../lib/*.pl", "../lib/commands/*.pl", "../lib/INI/*.p*") {
	push(@all_filepaths, glob($_));
}

print "Currently, we have these files: \n";
print join("\n", @all_filepaths);

my $total_cl;

foreach (@all_filepaths) {
	my @output = `wc -l $_`;

	foreach (@output) {
		my ($lines, $file) = split;
		$total_cl += $lines;
	}
}
print "\n\n$total_cl total lines of code \n";
