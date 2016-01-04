package Role::Mechanize;

use Moo::Role;

use Dancer2 qw/:syntax/;
use Test::WWW::Mechanize::PSGI;
use Types::Standard qw/InstanceOf/;

use namespace::clean;

has mech => (
    is  => 'lazy',
    isa => InstanceOf ['Test::WWW::Mechanize'],
    default => sub {
        Test::WWW::Mechanize::PSGI->new(
            app => sub {
                my $env = shift;
                load_app 'TestApp',;
                my $request = Dancer2::Request->new( env => $env );
                Dancer2->dance( $request );
            }
        );
    },
);

1;
