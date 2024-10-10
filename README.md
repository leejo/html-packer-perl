# NAME

HTML::Packer - Another HTML code cleaner

<div>

    <a href='https://travis-ci.org/leejo/html-packer-perl?branch=master'><img src='https://travis-ci.org/leejo/html-packer-perl.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/r/leejo/html-packer-perl'><img src='https://coveralls.io/repos/leejo/html-packer-perl/badge.png?branch=master' alt='Coverage Status' /></a>
</div>

# VERSION

Version 2.11

# DESCRIPTION

A HTML Compressor.

# SYNOPSIS

    use HTML::Packer;

    my $packer = HTML::Packer->init();

    $packer->minify( $scalarref, $opts );

To return a scalar without changing the input simply use (e.g. example 2):

    my $ret = $packer->minify( $scalarref, $opts );

For backward compatibility it is still possible to call 'minify' as a function:

    HTML::Packer::minify( $scalarref, $opts );

First argument must be a scalarref of HTML-Code.
Second argument must be a hashref of options. Possible options are

- remove\_comments

    HTML-Comments will be removed if 'remove\_comments' has a true value.  Comments starting with `<!--#`,
    `<!--[` or `<!-- google_ad_section_` will be preserved unless 'remove\_comments\_aggressive' has a true value. 

- remove\_comments\_aggressive

    See 'remove\_comments'.

- remove\_newlines

    ALL newlines will be removed if 'remove\_newlines' has a true value.

- do\_javascript

    Defines compression level for javascript. Possible values are 'clean', 'obfuscate', 'shrink' and 'best'.
    Default is no compression for javascript.
    This option only takes effect if [JavaScript::Packer](https://metacpan.org/pod/JavaScript%3A%3APacker) is installed.

- do\_stylesheet

    Defines compression level for CSS. Possible values are 'minify' and 'pretty'.
    Default is no compression for CSS.
    This option only takes effect if [CSS::Packer](https://metacpan.org/pod/CSS%3A%3APacker) is installed.

- do\_csp

    Defines hash algorithm for `Content-Security-Policy`, or CSP, hashes of
    embedded `<script>` and `<style>` tags.

    Allowed values are `'sha256'`, `'sha384'`, `'sha512'`.

    It may be left blank or set to a Perl false value to indicate that hashes
    should not be calculated, if performance is a concern.

- no\_compress\_comment

    If not set to a true value it is allowed to set a HTML comment that prevents the input being packed.

        <!-- HTML::Packer _no_compress_ -->

    Is not set by default.

- html5

    If set to a true value closing slashes will be removed from void elements.

- csp

    If `do_csp` is set to `'sha256'`, returns a hash that looks like this:

        (
            'script-src' => [qw( sha256-...= sha256-...= )],
            'style-src'  => [qw( sha256-...= sha256-...= )],
        )

    with each element of the `ARRAY`refs containing a CSP-friendly hash for a
    `<script>` or `<style>` tag.

# AUTHOR

Merten Falk, `<nevesenin at cpan.org>`. Now maintained by Lee
Johnson (LEEJO) with contributions from:

        Alexander Krizhanovsky <ak@natsys-lab.com>
        Bas Bloemsaat <bas@bloemsaat.com>
        girst <girst@users.noreply.github.com>
        Ankit Pati (ANKITPATI) <contact@ankitpati.in>

# BUGS

Please report any bugs or feature requests through
the web interface at [https://github.com/leejo/html-packer-perl/issues](https://github.com/leejo/html-packer-perl/issues). I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

perldoc HTML::Packer

# COPYRIGHT & LICENSE

Copyright 2009 - 2011 Merten Falk, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

# SEE ALSO

[HTML::Clean](https://metacpan.org/pod/HTML%3A%3AClean)
