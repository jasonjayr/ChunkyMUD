#!/usr/local/bin/perl -w
#   Generates a basic list of subroutines in source code files.
# Most of this code isn't mine, and I'm not entirely sure who the
# original author was. -malander
my $indexname = shift;
my $dirpath = shift;

if (not (defined $indexname) or not(defined $dirpath)) {
  die("You must provide an output index file\n");
}

my @files = glob("$dirpath/*.*");
my (@subnames, @allsubnames_bysub, @allsubnames_bymod);

foreach $filename (@files) {
    open (FILE, $filename);
    my @filetext = <FILE>;
    close (FILE);

    print "\t" . $filename . "\n";
    @subnames = map($_ =~ m/sub\s+([^\s]*)\s*\{/gi, @filetext);
    @subnames = grep($_ !~ m/^\s*$/, @subnames);
    @subnames = map { $_ . "()" } @subnames;

    if (not @subnames) {
      print "########## No subs ########## \n\n";
    } else {
      push @allsubnames_bysub, map ($_ . ": $filename", @subnames);
      push @allsubnames_bymod, map ("$filename: " . $_, @subnames);
      print join(", ", @subnames), "\n\n";
    }
}

@allsubnames_bysub = sort {lc($a) cmp lc($b)} @allsubnames_bysub;
@allsubnames_bymod = sort {lc($a) cmp lc($b)} @allsubnames_bymod;

open (INDEX, ">".$indexname) or die "Can't open index file: $!";
print INDEX "Function index organized by function\n\n";
print INDEX join("\n", @allsubnames_bysub) . "\n\n";

print INDEX "Function index organized by module\n\n";
print INDEX join("\n", @allsubnames_bymod);
close (INDEX);