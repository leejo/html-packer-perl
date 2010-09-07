#!perl -T

# =========================================================================== #

use Test::More;

my $not = 3;

SKIP: {
	eval( 'use HTML::Packer;' );

	skip( 'HTML::Packer not installed!', $not ) if ( $@ );

	plan tests => $not;

	minTest( 's1' );
	minTest( 's2', { 'remove_newlines' => 1 } );
	minTest( 's3', { 'remove_comments' => 1 } );
}

sub filesMatch {
	my $file1 = shift;
	my $file2 = shift;
	my $a;
	my $b;

	while (1) {
		$a = getc($file1);
		$b = getc($file2);

		if (!defined($a) && !defined($b)) { # both files end at same place
			return 1;
		}
		elsif (
			!defined($b) || # file2 ends first
			!defined($a) || # file1 ends first
			$a ne $b
		) {     # a and b not the same
			return 0;
		}
	}
}

sub minTest {
	my $filename = shift;
	my $opts = shift || {};

	open(INFILE, 't/html/' . $filename . '.html') or die("couldn't open file");
	open(GOTFILE, '>t/html/' . $filename . '-got.html') or die("couldn't open file");

	my $html = join( '', <INFILE> );

	my $packer = HTML::Packer->init();

	$packer->minify( \$html, $opts );
	print GOTFILE $html;
	close(INFILE);
	close(GOTFILE);

	open(EXPECTEDFILE, 't/html/' . $filename . '-expected.html') or die("couldn't open file");
	open(GOTFILE, 't/html/' . $filename . '-got.html') or die("couldn't open file");
	ok(filesMatch(GOTFILE, EXPECTEDFILE));
	close(EXPECTEDFILE);
	close(GOTFILE);
}

