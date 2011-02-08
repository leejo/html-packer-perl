#!perl -T

# =========================================================================== #

use Test::More;

my $js_input = <<EOT;

<script type="javascript">



  alert('test');</script>

<a href="/"  >link

1   < /a>


<!-- comment -->

    <  a href="/">   link 2
    < / a  >



EOT

my $css_input = <<EOT;


  <style type="text/css">

  foo {
    asdf:asdf;
    ew:12;
  }
</style>

<a href="/"  >link

1   < /a>


<!-- comment -->

    <  a href="/">   link 2
    < / a  >


EOT

my $js_expected_comp    = '<script type="javascript">/*<![CDATA[*/alert(\'test\');/*]]>*/</script><a href="/">link 1 </a> <a href="/"> link 2 </a>';
my $js_expected_nocdata = '<script type="javascript">alert(\'test\');</script><a href="/">link 1 </a> <a href="/"> link 2 </a>';
my $js_expected_nocomp  = '<script type="javascript">' . "\n\n\n\n" . '  alert(\'test\');</script><a href="/">link 1 </a> <a href="/"> link 2 </a>';

my $css_expected_comp   = '<style type="text/css">' . "\nfoo{\nasdf:asdf;\new:12;\n}\n" . '</style><a href="/">link 1 </a> <a href="/"> link 2 </a>';
my $css_expected_nocomp = '<style type="text/css">' . "\n\n  foo {\n    asdf:asdf;\n    ew:12;\n  }\n" . '</style><a href="/">link 1 </a> <a href="/"> link 2 </a>';

my $not = 9;

SKIP: {
    eval { use HTML::Packer; };

    skip( 'HTML::Packer not installed!', $not ) if ( $@ );

    plan tests => $not;

    minTest( 's1', undef, 'Test without opts.' );
    minTest( 's2', { remove_newlines => 1 }, 'Test remove_newlines.' );
    minTest( 's3', { remove_comments => 1 }, 'Test remove_comments.' );
    minTest( 's4', { remove_comments => 1, remove_newlines => 1 }, 'Test remove_newlines and remove_comments.' );
    minTest( 's5', { remove_comments => 1, remove_newlines => 1 }, 'Test _no_compress_ comment.' );
    minTest( 's6', { remove_comments => 1, remove_newlines => 1, no_compress_comment => 1 }, 'Test _no_compress_ comment with no_compress_comment option.' );

    my $packer = HTML::Packer->init();
    my $js_comp_input   = $js_input;
    my $js_cdata_input  = $js_input;
    $packer->minify( \$js_comp_input, { remove_comments => 1, remove_newlines => 1, do_javascript => 'minify' } );
    $packer->minify( \$js_cdata_input, { remove_comments => 1, remove_newlines => 1, do_javascript => 'minify', no_cdata => 1 } );

    eval "use JavaScript::Packer $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER;";
    if ( $@ ) {
        is( $js_comp_input, $js_expected_nocomp, 'Test do_javascript. JavaScript::Packer >= ' . $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER . ' not installed.' );
        is( $js_cdata_input, $js_expected_nocomp, 'Test do_javascript 2. JavaScript::Packer >= ' . $HTML::Packer::REQUIRED_JAVASCRIPT_PACKER . ' not installed.' );
    }
    else {
        is( $js_comp_input, $js_expected_comp, 'Test do_javascript. JavaScript::Packer installed.' );
        is( $js_cdata_input, $js_expected_nocdata, 'Test do_javascript 2. JavaScript::Packer installed.' );
    }

    $packer->minify( \$css_input, { remove_comments => 1, remove_newlines => 1, do_stylesheet => 'pretty' } );

    eval "use CSS::Packer $HTML::Packer::REQUIRED_CSS_PACKER;";
    if ( $@ ) {
        is( $css_input, $css_expected_nocomp, 'Test do_stylesheet. CSS::Packer >= ' . $HTML::Packer::REQUIRED_CSS_PACKER . ' not installed.' );
    }
    else {
        is( $css_input, $css_expected_comp, 'Test do_stylesheet. CSS::Packer installed.' );
    }
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
    my $message = shift || '';

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
    ok(filesMatch(GOTFILE, EXPECTEDFILE), $message );
    close(EXPECTEDFILE);
    close(GOTFILE);
}
