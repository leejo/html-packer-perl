use strict;
use warnings;

use inc::Module::Install;

all_from        'lib/HTML/Packer.pm';
test_requires   'Test::More'        => 0;
requires        'Regexp::RegGrp'    => "0.0201";

repository 'http://github.com/nevesenin/html-packer-perl';

clean_files 't/html/s?-got.html';

auto_install();
WriteAll();