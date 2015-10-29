package t::lib::TestAccountApp;

use Dancer2;
use Dancer2::Plugin::Interchange6 ();
use Dancer2::Plugin::Interchange6::Routes;

shop_setup_routes;

1;
