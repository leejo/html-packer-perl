#!/usr/bin/env perl

use strict;
use warnings;

use HTML::Packer;

use Test::More tests => 3;

my @tests = (
    {
        description => '<script type="module"> in <head>, no HTML5',
        config => {
            do_csp => 'sha256',
        },
        csp => {
            'script-src' => [qw(
            )],
            'style-src' => [qw(
            )],
        },
        html => <<'EOS',
<!DOCTYPE html>
<html>
    <head>
        <title>Hello!</title>
        <script type="module">
            alert("hello, world");
        </script>
    </head>
    <body>
        Hello, World!
    </body>
</html>
EOS
    },
    {
        description => '<script type="module"> in <head>, sha256',
        config => {
            do_csp => 'sha256',
            html5 => 1,
        },
        csp => {
            'script-src' => [qw(
                'sha256-791JliCfVfBg+ax8zg5KqhP+kgkqzbJzBcpFDrZQnkc='
            )],
            'style-src' => [qw(
            )],
        },
        html => <<'EOS',
<!DOCTYPE html>
<html>
    <head>
        <title>Hello!</title>
        <script type="module">
            alert("hello, world");
        </script>
    </head>
    <body>
        Hello, World!
    </body>
</html>
EOS
    },
    {
        description => 'multiple <script type="module">s in <head> & <body>,'.
                       ' sha384',
        config => {
            do_csp => 'sha384',
            html5 => 1,
        },
        csp => {
            'script-src' => [qw(
                'sha384-GmztkaupfNN5LCa4R3NR92UcwhOPA0C1u4dfOmu7LVDgWTK/nb06W1MXUmCXcC7d='
                'sha384-2MKGGo4REN2gDPFYzCEFbsBLEaaGWN3NtW+5ss3IynhQy0gVzGNjPhIAaQkQsRzl='
                'sha384-bMGstjmVvi+Hidcx4LpW/d3H8fNrKdkuh7zPgP7ygX/nKjqkKGgkJYFCgp7T91wP='
                'sha384-8QFfvbKGXjYGVXD3XCs7As+GxXSe2QOYlCfZK0BwnXoRQnysSDUqmxiQl0gFz3Xv='
            )],
            'style-src' => [qw(
            )],
        },
        html => <<'EOS',
<html>
    <head>
        <script type="module">
            alert("hello, world");
        </script>
    </head>
    <body>
        Hello, World!
        <script type="module">
            alert("bye, world");
        </script>
        <script type="module">
            alert("this could be a stored XSS!");
        </script>
    </body>
    <script type="module">
        alert("carrier-injected code goes here");
    </script>
</html>
EOS
    },
);

foreach my $test ( @tests ) {
    my $packer = HTML::Packer->init;

    my $html = $test->{html};
    $packer->minify( \$html, $test->{config} );

    is_deeply( { $packer->csp }, $test->{csp}, $test->{description} );
}
