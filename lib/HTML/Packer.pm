package HTML::Packer;

use 5.008;
use strict;
use warnings;
use Carp;

use vars qw/$VERSION $PLACEHOLDER/;

$VERSION = '0.4';

$PLACEHOLDER = 'hp_';

# -----------------------------------------------------------------------------

sub minify {
# Some regular expressions are from HTML::Clean
	my ( $scalarref, $opts ) = @_;
	
	if ( ref( $scalarref ) ne 'SCALAR' ) {
		carp( 'First argument must be a scalarref!' );
		return '';
	}
	
	return '' if ( ${$scalarref} eq '' );
	
	if ( ref( $opts ) ne 'HASH' ) {
		carp( 'Second argument must be a hashref of options! Using defaults!' ) if ( $opts );
		$opts = {
			'remove_comments'	=> 0,
			'remove_newlines'	=> 0,
			'do_javascript'		=> '',	# minify, shrink, base62
			'do_stylesheet'		=> '',	# pretty, minify
		};
	}
	else {
		$opts->{'remove_comments'}	= $opts->{'remove_comments'} ? 1 : 0;
		$opts->{'remove_newlines'}	= $opts->{'remove_newlines'} ? 1 : 0;
		$opts->{'do_javascript'}	= grep( $opts->{'do_javascript'}, ( 'minify', 'shrink', 'base62' ) ) ? $opts->{'do_javascript'} : '';
		$opts->{'do_stylesheet'}	= grep( $opts->{'do_stylesheet'}, ( 'minify', 'pretty' ) ) ? $opts->{'do_stylesheet'} : '';
	}
	
	if ( $opts->{'do_javascript'} ) {
		eval( 'require JavaScript::Packer;' );
		
		if ( $@ ) {
			$opts->{'do_javascript'} = '';
		}
	}
	if ( $opts->{'do_stylesheet'} ) {
		eval( 'require CSS::Packer;' );
		
		if ( $@ ) {
			$opts->{'do_stylesheet'} = '';
		}
	}
	
	${$scalarref} =~ s/<!--~\Q$PLACEHOLDER\E\d+~-->//gsm;
	${$scalarref} =~ s/<!--([^#].*?)?-->//gsm if ( $opts->{'remove_comments'} );
	
	my $unclean = {};
	
	my $_replace_unclean = sub {
		my ( $opening, $content, $closing ) = @_;
		
		return '' unless ( $opening );
		
		my $key = $PLACEHOLDER . scalar( keys( %$unclean ) );
		
		if ( not $content and not $closing ) {
			$unclean->{$key} = $opening;
		}
		else {
			if ( $content ) {
				if ( $opening =~ /<\s*script[^>]*(?:java|ecma)script[^>]*>/ and $opts->{'do_javascript'} ) {
					JavaScript::Packer::minify( \$content, { 'compress' => $opts->{'do_javascript'} } );
					$content = '/*<![CDATA[*/' . $content . '/*]]>*/';
				}
				elsif ( $opening =~ /<\s*style[^>]*text\/css[^>]*>/ and $opts->{'do_stylesheet'} ) {
					CSS::Packer::minify( \$content, { 'compress' => $opts->{'do_stylesheet'} } );
				}
			}
			else {
				$content = '';
			}
			$opening =~ s/[^\S\n]{2,}/ /msg;
			$opening =~ s/\s+>/>/sgm;
			$opening =~ s/<\s+/</sgm;
			$closing =~ s/[^\S\n]{2,}/ /msg;
			$closing =~ s/\s+>/>/sgm;
			$closing =~ s/<\s+/</sgm;
			$closing =~ s/<\/\s+/<\//sgm;
			
			$unclean->{$key} = $opening . $content . $closing;
		}
		
		return '<!--~' . $key . '~-->';
	};
	
	${$scalarref} =~ s/(<\!DOCTYPE[^>]*>)/&$_replace_unclean( $& )/xmse;
	
	${$scalarref} =~ s/(<\s*(pre|code|textarea|script|style)[^>]*>)(.*?)(<\s*\/\2[^>]*>)/&$_replace_unclean( $1, $3, $4 )/gmsie;
	
	my @tags = (
		'a', 'abbr', 'acronym', 'address', 'b', 'bdo', 'big', 'button', 'cite',
		'del', 'dfn', 'em', 'font', 'i', 'input', 'ins', 'kbd', 'label', 'q',
		's', 'samp', 'select', 'small', 'strike', 'strong', 'sub', 'sup', 'u', 'var'
	);
	
	${$scalarref} =~ s/^\s*//sg;
	${$scalarref} =~ s/\s*$//sg;
	${$scalarref} =~ s/[^\S\n]*$//smg;
	${$scalarref} =~ s/^[^\S\n]*//smg;
	${$scalarref} =~ s/[^\S\n]*\n/\n/sg;
	${$scalarref} =~ s/[^\S\n]{2,}/ /sg;
	${$scalarref} =~ s/\n{2,}/\n/sg;
	${$scalarref} =~ s/\s+>/>/sg;
	${$scalarref} =~ s/<\s+/</sg;
	${$scalarref} =~ s/<\/\s+/<\//sg;
	
	if ( $opts->{'remove_newlines'} ) {
		foreach ( @tags ) {
			${$scalarref} =~ s/[^\S]+(<\s*\/?\s*\Q$_\E( [^>]*)?>)/ $1/ismg;
			${$scalarref} =~ s/(<\s*\/?\s*\Q$_\E( [^>]*)?>)[^\S]+/$1 /ismg;
		}
		
		${$scalarref} =~ s/>\n</></g;
		${$scalarref} =~ s/([^>])\n</$1</g;
		${$scalarref} =~ s/>\n([^<])/>$1/g;
		${$scalarref} =~ s/(\w)\n(\w)/$1 $2/g;
		${$scalarref} =~ s/([^>])\n([^>])/$1 $2/g;
		${$scalarref} =~ s/\n//g;
	}
	
	${$scalarref} =~ s/<!--~(\Q$PLACEHOLDER\E\d+)~-->/$unclean->{$1}/gsme;
	
	${$scalarref} =~ s/[^\S\n]*(<!--([^#].*?)?-->)[^\S\n]*/$1/gsm unless ( $opts->{'remove_comments'} );
}

1;

__END__

=head1 NAME

HTML::Packer - Another HTML code cleaner

=head1 VERSION

Version 0.4

=head1 SYNOPSIS

    use HTML::Packer;

    HTML::Packer::minify( $scalarref, $opts );

=head1 DESCRIPTION

A HTML Compressor.

=head1 FUNCTIONS

=head2 HTML::Packer::minify( $scalarref, $opts );

First argument must be a scalarref of HTML-Code.
Second argument must be a hashref of options. Possible options are

=over 4

=item remove_comments

HTML-Comments will be removed if 'remove_comments' has a true value.

=item remove_newlines

ALL newlines will be removed if 'remove_newlines' has a true value.

=item do_javascript

Defines compression level for javascript. Possible values are 'minify', 'shrink' and 'base62'.
Default is no compression for javascript.
This option only takes effect if L<JavaScript::Packer> is installed.

=item do_stylesheet

Defines compression level for CSS. Possible values are 'minify' and 'pretty'.
Default is no compression for CSS.
This option only takes effect if L<CSS::Packer> is installed.

=back

=head1 AUTHOR

Merten Falk, C<< <nevesenin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-packer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Packer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc HTML::Packer

=head1 COPYRIGHT & LICENSE

Copyright 2009 Merten Falk, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::Clean>

=cut
