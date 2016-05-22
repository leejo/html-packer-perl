use strict;
use warnings;

use inc::Module::Install;

all_from        'lib/HTML/Packer.pm';
test_requires   'Test::More'        => 0;
requires        'Regexp::RegGrp'    => "1.001_001";
requires        'CSS::Packer'       => "2.01";
requires        'JavaScript::Packer'=> "2.01";

repository 'http://github.com/leejo/html-packer-perl';
bugtracker 'http://github.com/leejo/html-packer-perl/issues';

clean_files 't/html/s?-got.html';

auto_install();
WriteAll();
