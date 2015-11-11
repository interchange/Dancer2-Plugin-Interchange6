package t::lib::TestAccountApp;

BEGIN {
    use Dancer2;
    set views => "t/routes/views";

    set plugins => {
        'Auth::Extensible' => {
            realms => {
                users => {
                    provider => 'DBIC',
                }
            }
        },
        'DBIC' => {
            default => {
                dsn          => "DBI:SQLite:" . ${main::filename},
                schema_class => 'Interchange6::Schema',
            }
        },
    };
}

use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Interchange6;
use Dancer2::Plugin::Interchange6::Routes;

shop_setup_routes;

1;
