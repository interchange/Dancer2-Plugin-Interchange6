package Test::API;

use strict;
use warnings;

use JSON::MaybeXS;
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::WWW::Mechanize::PSGI;

{
    package TestApp1;
    use Dancer2;
    use Dancer2::Plugin::Interchange6::API;
}

my $app  = TestApp1->to_app;
my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );

sub run_tests {
    diag "Test::API";

    $mech->get_ok('/api/product/os28005', 'GET /api/product/os28005 OK');

    diag $mech->content;

};

1;
