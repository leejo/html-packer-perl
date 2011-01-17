package HTML::Packer;

use 5.008009;
use strict;
use warnings;
use Carp;
use Regexp::RegGrp;

# -----------------------------------------------------------------------------

our $VERSION = '1.000';

our @TAGS = (
    'a', 'abbr', 'acronym', 'address', 'b', 'bdo', 'big', 'button', 'cite',
    'del', 'dfn', 'em', 'font', 'i', 'input', 'ins', 'kbd', 'label', 'q',
    's', 'samp', 'select', 'small', 'strike', 'strong', 'sub', 'sup', 'u', 'var'
);

# Some regular expressions are from HTML::Clean

our $COMMENT        = '((?>\s*))(<!--(?:(?:[^#\[]|(?! google_ad_section_)).*?)?-->)((?>\s*))';

our $PACKER_COMMENT = '<!--\s*HTML::Packer\s*(\w+)\s*-->';

our $DOCTYPE        = '<\!DOCTYPE[^>]*>';

our $DONT_CLEAN     = '(<\s*(pre|code|textarea|script|style)[^>]*>)(.*?)(<\s*\/\2[^>]*>)';

our $WHITESPACES    = [
    {
        regexp      => qr/^\s*/s,
        replacement => ''
    },
    {
        regexp      => qr/\s*$/s,
        replacement => ''
    },
    {
        regexp      => '^\s*',
        replacement => '',
        modifier    => 'm'
    },
    {
        regexp      => '\s*$',
        replacement => '',
        modifier    => 'm'
    },
    {
        regexp      => qr/(?<=>)[^<>]*(?=<)/sm,
        replacement => sub {
            my $match = $_[0]->{match};

            $match =~ s/[^\S\n]{2,}/ /sg;
            $match =~ s/\s*\n+\s*/\n/sg;

            return $match;
        }
    },
    {
        regexp      => '<\s*(\/)?\s*',
        replacement => sub {
            return sprintf( '<%s', $_[0]->{submatches}->[0] );
        },
        modifier    => 's'
    },
    {
        regexp      => '\s*(\/)?\s*>',
        replacement => sub {
            return sprintf( '%s>', $_[0]->{submatches}->[0] );
        },
        modifier    => 's'
    }
];

our $NEWLINES_TAGS = [
    {
        regexp      => '(\s*)(<\s*\/?\s*(?:' . join( '|', @TAGS ) . ')[^>]*>)(\s*)',
        replacement => sub {
            return sprintf( '%s%s%s', $_[0]->{submatches}->[0] ? ' ' : '', $_[0]->{submatches}->[1], $_[0]->{submatches}->[2] ? ' ' : '' );
        },
        modifier    => 'is'
    }
];

our $NEWLINES = [
    {
        regexp      => '(.)\n(.)',
        replacement => sub {
            my ( $pre, $post ) = @{$_[0]->{submatches}};

            my $ret;

            if ( $pre eq '>' or $post eq '<' ) {
                $ret = $pre . $post;
            }
            elsif ( $pre =~ /[\w-]/ and $post =~ /[\w-]/ ) {
                $ret = $pre . ' ' . $post;
            }
            else {
                $ret = $pre . $post;
            }

            return $ret;
        }
    }
];

sub init {
    my $class = shift;
    my $self  = {};

    eval {
        require JavaScript::Packer;
    };
    $self->{can_do_javascript}  = $@ ? 0 : 1;
    $self->{javascript_packer}  = undef;
    eval {
        require CSS::Packer;
    };
    $self->{can_do_stylesheet}  = $@ ? 0 : 1;
    $self->{css_packer}         = undef;

    $self->{whitespaces}->{reggrp_data}   = $WHITESPACES;
    $self->{newlines}->{reggrp_data}      = $NEWLINES;
    $self->{newlines_tags}->{reggrp_data} = $NEWLINES_TAGS;
    $self->{global}->{reggrp_data}        = [
        {
            regexp      => $DOCTYPE,
            replacement => sub {
                return '<!--~' . $_[0]->{store_index} . '~-->';
            },
            store => sub {
                my $doctype = $_[0]->{match};

                $doctype =~ s/\s+/ /gsm;

                return $doctype;
            }
        },
        {
            regexp      => $COMMENT,
            replacement => sub {
                my $opts            = $_[0]->{opts} || {};
                my $remove_comments = _get_opt( $opts, 'remove_comments' );
                my $remove_newlines = _get_opt( $opts, 'remove_newlines' );

                return $remove_comments ? (
                    $remove_newlines ? ' ' : (
                        ( $_[0]->{submatches}->[0] =~ /\n/s or $_[0]->{submatches}->[2] =~ /\n/s ) ? "\n" : ''
                    )
                ) : '<!--~' . $_[0]->{store_index} . '~-->';
            },
            store => sub {
                my $opts            = $_[0]->{opts} || {};
                my $remove_comments = _get_opt( $opts, 'remove_comments' );
                my $remove_newlines = _get_opt( $opts, 'remove_newlines' );

                my $ret = $remove_comments ? '' : (
                     ( ( not $remove_newlines and $_[0]->{submatches}->[0] =~ /\n/s ) ? "\n" : '' ) .
                     $_[0]->{submatches}->[1] .
                     ( ( not $remove_newlines and $_[0]->{submatches}->[2] =~ /\n/s ) ? "\n" : '' )
                );

                return $ret;
            }
        },
        {
            regexp      => $DONT_CLEAN,
            replacement => sub {
                return '<!--~' . $_[0]->{store_index} . '~-->';
            },
            store => sub {
                my ( $opening, undef, $content, $closing )  = @{$_[0]->{submatches}};
                my $opts                                    = $_[0]->{opts} || {};

                if ( $content ) {
                    if ( $opening =~ /<\s*script[^>]*(?:java|ecma)script[^>]*>/ and $self->{javascript_packer} ) {
                        my $do_javascript = _get_opt( $opts, 'do_javascript' );
                        if ( $do_javascript ) {
                            my $no_cdata = _get_opt( $opts, 'no_cdata' );
                            $self->{javascript_packer}->minify( \$content, { compress => $do_javascript } );
                            unless ( $no_cdata ) {
                                $content = '/*<![CDATA[*/' . $content . '/*]]>*/';
                            }
                        }
                    }
                    elsif ( $opening =~ /<\s*style[^>]*text\/css[^>]*>/ and $self->{css_packer} ) {
                        my $do_stylesheet = _get_opt( $opts, 'do_stylesheet' );
                        if ( $do_stylesheet ) {
                            $self->{css_packer}->minify( \$content, { compress => $do_stylesheet } );
                            $content = "\n" . $content if ( $do_stylesheet eq 'pretty' );
                        }
                    }
                }
                else {
                    $content = '';
                }

                # I don't like this, but
                # $self->{whitespaces}->{reggrp}->exec( \$opening );
                # will not work. It isn't initialized jet.
                # If someone has a better idea, please let me know
                $self->_process_wrapper( 'whitespaces', \$opening );
                $self->_process_wrapper( 'whitespaces', \$closing );

                return $opening . $content . $closing;
            },
            modifier    => 'ism'
        }
    ];

    map {
        $self->{$_}->{reggrp} = Regexp::RegGrp->new( { reggrp => $self->{$_}->{reggrp_data} } );
    } ( 'newlines', 'newlines_tags', 'whitespaces' );

    $self->{global}->{reggrp} = Regexp::RegGrp->new(
        {
            reggrp          => $self->{global}->{reggrp_data},
            restore_pattern => qr/<!--~(\d+)~-->/
        }
    );

    bless( $self, $class );

    return $self;
}

sub minify {
    my ( $self, $input, $opts );

    unless (
        ref( $_[0] ) and
        ref( $_[0] ) eq __PACKAGE__
    ) {
        $self = __PACKAGE__->init();

        shift( @_ ) unless ( ref( $_[0] ) );

        ( $input, $opts ) = @_;
    }
    else {
        ( $self, $input, $opts ) = @_;
    }

    if ( ref( $input ) ne 'SCALAR' ) {
        carp( 'First argument must be a scalarref!' );
        return undef;
    }

    my $html    = \'';
    my $cont    = 'void';

    if ( defined( wantarray ) ) {
        my $tmp_input = ref( $input ) ? ${$input} : $input;

        $html   = \$tmp_input;
        $cont   = 'scalar';
    }
    else {
        $html = ref( $input ) ? $input : \$input;
    }

    if ( $self->{can_do_javascript} and not $self->{javascript_packer_isset} ) {
        $self->{javascript_packer} = eval {
            JavaScript::Packer->init();
        };
        $self->{javascript_packer_isset} = 1;
    }

    if ( $self->{can_do_stylesheet} and not $self->{css_packer_isset} ) {
        $self->{css_packer} = eval {
            CSS::Packer->init();
        };
        $self->{css_packer_isset} = 1;
    }

    if ( ref( $opts ) ne 'HASH' ) {
        carp( 'Second argument must be a hashref of options! Using defaults!' ) if ( $opts );
        $opts = {
            remove_comments     => 0,
            remove_newlines     => 0,
            do_javascript       => '',  # minify, shrink, base62
            do_stylesheet       => '',  # pretty, minify
            no_compress_comment => 0,
            no_cdata            => 0
        };
    }
    else {
        $opts->{remove_comments} = $opts->{remove_comments} ? 1 : 0;
        $opts->{remove_newlines} = $opts->{remove_newlines} ? 1 : 0;
        $opts->{do_javascript}   = (
            grep( $opts->{do_javascript}, ( 'minify', 'shrink', 'base62' ) ) &&
            $self->{javascript_packer}
        ) ? $opts->{do_javascript} : '';

        $opts->{do_stylesheet}  = (
            grep( $opts->{do_stylesheet}, ( 'minify', 'pretty' ) ) &&
            $self->{css_packer}
        ) ? $opts->{do_stylesheet} : '';

        $opts->{no_compress_comment}    = $opts->{no_compress_comment} ? 1 : 0;
        $opts->{no_cdata}               = $opts->{no_cdata} ? 1 : 0;
    }

    if ( not $opts->{no_compress_comment} and ${$html} =~ /$PACKER_COMMENT/s ) {
        my $compress = $1;
        if ( $compress eq '_no_compress_' ) {
            return ( $cont eq 'scalar' ) ? ${$html} : undef;
        }
    }

    $self->{global}->{reggrp}->exec( $html, $opts );
    $self->{whitespaces}->{reggrp}->exec( $html, $opts );
    if ( $opts->{remove_newlines} ) {
        $self->{newlines_tags}->{reggrp}->exec( $html );
        $self->{newlines}->{reggrp}->exec( $html );
    }

    $self->{global}->{reggrp}->restore_stored( $html );

    return ${$html} if ( $cont eq 'scalar' );
}

sub _get_opt {
    my ( $opts_hash, $opt ) = @_;

    $opts_hash  ||= {};
    $opt        ||= '';

    my $ret = '';

    $ret = $opts_hash->{$opt} if ( defined( $opts_hash->{$opt} ) );

    return $ret;
}

sub _process_wrapper {
    my ( $self, $reg_name, $in, $opts ) = @_;

    $self->{$reg_name}->{reggrp}->exec( $in, $opts );
}

1;

__END__

=head1 NAME

HTML::Packer - Another HTML code cleaner

=head1 VERSION

Version 1.000

=head1 DESCRIPTION

A HTML Compressor.

=head1 SYNOPSIS

    use HTML::Packer;

    my $packer = HTML::Packer->init();

    $packer->minify( $scalarref, $opts );

To return a scalar without changing the input simply use (e.g. example 2):

    my $ret = $packer->minify( $scalarref, $opts );

For backward compatibility it is still possible to call 'minify' as a function:

    HTML::Packer::minify( $scalarref, $opts );

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

=item no_compress_comment

If not set to a true value it is allowed to set a HTML comment that prevents the input being packed.

    <!-- HTML::Packer _no_compress_ -->

Is set by default.

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

Copyright 2009 - 2011 Merten Falk, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::Clean>

=cut
