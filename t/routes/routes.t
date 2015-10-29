#! perl
#
# IMPORTANT: these tests cannot live directly under 't' since Dancer2 merrily
# trashes appdir under certain circumstances when we live there.

use strict;
use warnings;

use Test::Most;

use DBD::SQLite;
use File::Spec;
use Data::Dumper;

use lib File::Spec->catdir( 't', 'routes', 'lib' );

use Interchange6::Schema;
use Interchange6::Schema::Populate::CountryLocale;

use Dancer2;
use Dancer2::Plugin::Interchange6;
use TestApp;

diag( "Testing with DBD::SQLite $DBD::SQLite::VERSION" );

# let's test
use Test::WWW::Mechanize::PSGI;

my $mech = Test::WWW::Mechanize::PSGI->new(
    app =>  TestApp->to_app
);

# product

$mech->get_ok ( '/kilo-of-bananas' , "GET /kilo-of-bananas (product route)");
$mech->content_like( qr/name="bananas"/, 'found bananas');

# lives_ok { $resp = dancer_response GET => '/kilo-of-potatoes' }
# "GET /kilo-of-potatoes (product route)";

# response_status_is $resp => 200, 'status is ok';
# response_content_like $resp => qr|name="potatoes"|, 'found potatoes';

# lives_ok { $resp = dancer_response GET => '/CAR002' }
# "GET /CAR002 (product route)";

# response_status_is $resp => 301, 'status is 301';
# response_headers_include $resp =>
#   [ Location => 'http://localhost/kilo-of-carrots' ],
#   "Check redirect path";

# # navigation

# lives_ok { $resp = dancer_response GET => '/fruit' }
# "GET /fruit (navigation route)";

# response_status_is $resp    => 200,              'status is ok';
# response_content_like $resp => qr|name="Fruit"|, 'found Fruit';
# response_content_like $resp => qr|products="bananas,oranges"|,
#   'found bananas,oranges';

# lives_ok { $resp = dancer_response GET => '/vegetables' }
# "GET /vegetables (navigation route)";

# response_status_is $resp => 200, 'status is ok';
# response_content_like $resp => qr|name="Vegetables"|, 'found Vegetables';
# response_content_like $resp => qr|products="carrots,potatoes"|,
#   'found carrots,potatoes';

# # cart

# lives_ok { $resp = dancer_response GET => '/cart' } "GET /cart";

# response_status_is $resp => 200, 'status is ok';

# %form = ( sku => 'BAN001', );

# lives_ok { $resp = dancer_response( POST => '/cart', { body => {%form} } ) }
# "POST /cart add bananas";

# response_status_is $resp => 200, 'status is ok';
# response_content_like $resp => qr/cart_subtotal="5.34"/, 'cart_subtotal is 5.34';
# response_content_like $resp => qr/cart_total="5.34"/, 'cart_total is 5.34';
# response_content_like $resp => qr/cart="BAN001:bananas:1:5.34"/,
#   'found qty 1 bananas in cart';

# %form = ( sku => 'POT002', );

# lives_ok { $resp = dancer_response( POST => '/cart', { body => {%form} } ) }
# "POST /cart add potatoes";

# response_status_is $resp => 200, 'status is ok';
# response_content_like $resp => qr/cart_total="15.49"/, 'cart_total is 15.49';
# response_content_like $resp =>
#   qr/cart="BAN001:bananas:1:5.34,POT002:potatoes:1:10.15"/,
#   'found bananas & potatoes in cart';

# lives_ok { $resp = dancer_response GET => '/cart' } "GET /cart";

# response_status_is $resp => 200, 'status is ok';
# response_content_like $resp => qr/cart_total="15.49"/, 'cart_total is 15.49';
# response_content_like $resp =>
#   qr/cart="BAN001:bananas:1:5.34,POT002:potatoes:1:10.15"/,
#   'found bananas & potatoes in cart';

# # login

# # grab session id - we want to make sure it does NOT change on login
# # but that it DOES change after logout

# lives_ok { $resp = dancer_response GET => '/sessionid' } "GET /sessionid";
# $sessionid = $resp->content;

# lives_ok { $resp = dancer_response GET => '/private' }
# "GET /private (login restricted)";

# response_redirect_location_is $resp =>
#   'http://localhost/login?return_url=%2Fprivate',
#   "Redirected to /login";

# lives_ok { $resp = dancer_response GET => '/login' } "GET /login";

# response_status_is $resp    => 200,            'status is ok';
# response_content_like $resp => qr/Login form/, 'got login page';

# # bad login

# read_logs;    # clear logs

# %form = (
#     username => 'testuser',
#     password => 'badpassword'
# );

# lives_ok { $resp = dancer_response( POST => '/login', { body => {%form} } ) }
# "POST /login with bad password";

# response_status_is $resp    => 200,            'status is ok';
# response_content_like $resp => qr/Login form/, 'got login page';

# $logs = read_logs;
# cmp_deeply(
#     $logs,
#     [
#         ignore(),
#         ignore(),
#         { level => "debug", message => "Authentication failed for testuser" }
#     ],
#     "Check auth failed debug message"
# ) || diag Dumper($logs);

# # good login

# read_logs;    # clear logs

# %form = (
#     username => 'testuser',
#     password => 'mypassword'
# );

# lives_ok { $resp = dancer_response( POST => '/login', { body => {%form} } ) }
# "POST /login with good password";

# response_redirect_location_is $resp => 'http://localhost/', "Redirected to /";

# $logs = read_logs;
# cmp_deeply(
#     $logs,
#     [
#         ignore(),
#         ignore(),
#         { level => "debug", message => "users accepted user testuser" },
#         {
#             level   => "debug",
#             message => re('Change users_id.+to:.+> 1')
#         }
#     ],
#     "login successful and users_id set in debug logs"
# ) || diag Dumper($logs);

# lives_ok { $resp = dancer_response GET => '/sessionid' } "GET /sessionid";
# cmp_ok( $resp->content, 'eq', $sessionid, "Check session id has not changed");

# # we should now be able to GET /private

# lives_ok { $resp = dancer_response GET => '/private' }
# "GET /private (login restricted)";

# response_status_is $resp    => 200,            'status is ok';
# response_content_like $resp => qr/Private page/, 'got private page';

# # checkout

# lives_ok { $resp = dancer_response GET => '/checkout' } "GET /checkout";

# response_status_is $resp => 200, 'status is ok';
# response_content_like $resp => qr/cart_subtotal="15.49"/, 'cart_subtotal is 15.49';
# response_content_like $resp => qr/cart_total="15.49"/, 'cart_total is 15.49';
# response_content_like $resp =>
#   qr/cart="BAN001:bananas:1:5.34,POT002:potatoes:1:10.15"/,
#   'found bananas & potatoes at checkout';

# # logout

# read_logs;    # clear logs
# lives_ok { $resp = dancer_response GET => '/logout' } "GET /logout";
# response_redirect_location_is $resp => 'http://localhost/', "Redirected to /";

# $logs = read_logs;
# cmp_deeply(
#     $logs,
#     [
#         ignore(),
#         ignore(),
#         { level => "debug", message => re('Change sessions_id.+undef') }
#     ],
#     "Check sessions_id undef debug message"
# ) || diag Dumper($logs);

# lives_ok { $resp = dancer_response GET => '/sessionid' } "GET /sessionid";
# cmp_ok( $resp->content, 'ne', $sessionid, "Check session id has changed");

# lives_ok { $resp = dancer_response GET => '/private' }
# "GET /private (login restricted)";

# response_redirect_location_is $resp =>
#   'http://localhost/login?return_url=%2Fprivate',
#   "Redirected to /login";

# lives_ok { $resp = dancer_response GET => '/cart' } "GET /cart";

# response_status_is $resp => 200, 'status is ok';
# response_content_like $resp => qr/cart_total="0"/, 'cart_total is 0';
# response_content_like $resp => qr/cart=""/, 'cart is empty';

done_testing;
