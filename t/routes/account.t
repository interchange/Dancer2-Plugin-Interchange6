use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(GET POST);

{
    package MyApp;
    use Dancer2;
    use t::lib::TestAccountApp;
}

my $app = Dancer2->runner->psgi_app;
is( ref $app, 'CODE', 'Got app' );

test_psgi $app, sub {
    my $cb = shift;

    {
        # login test
        my $res = $cb->( POST '/login' );
        is( $res->code, 401, 'HTTP status for POST /login without input' );

        my $content = $res->content;
        like( $res->content, qr%<h1>Login Required</h1>%,
              'Content for POST /login without input' );
    }
};

done_testing;
