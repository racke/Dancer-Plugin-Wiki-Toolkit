#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::Wiki::Toolkit' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::Wiki::Toolkit $Dancer::Plugin::Wiki::Toolkit::VERSION, Perl $], $^X" );
