package Test::Cart;

use Test::More;
use Test::Deep;
use Test::Exception;

use Dancer2 appname => 'TestApp';
use Dancer2::Plugin::Interchange6;
use Dancer2::Plugin::Interchange6::Cart;

my $app = dancer_app;
my $trap = $app->logger_engine->trapper;
my $plugin = $app->with_plugin('Dancer2::Plugin::Interchange6');

sub run_tests {
    diag "Test::Cart";

    $trap->read;    # empty it

    subtest 'cart unit tests' => sub {

        #plan tests => 21;

        my $schema = shop_schema;
        $schema->resultset('Cart')->delete_all;

        my ( $cart, $log );

        # new cart with no args

        lives_ok {
            $schema->resultset('Session')
              ->create( { sessions_id => '123456789', session_data => '' } )
        }
        "create empty session";

        throws_ok { Dancer2::Plugin::Interchange6::Cart->new() }
        qr/Missing required arguments: plugin, schema, sessions_id/,
          "new cart with no args dies"
          or diag explain $trap->read;

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                sessions_id => 123456789,
                schema      => $schema,
                plugin      => $plugin,
            );
        }
        "new cart with minimum args lives" or diag explain $trap->read;

        $log = $trap->read->[0];
        cmp_deeply(
            $log,
            superhashof(
                {
                    level   => "debug",
                    message => re(qr/^New cart \d+ main\.$/)
                }
            ),
            'debug: New cart \d+ main.'
        ) or diag explain $log;

        cmp_ok $schema->resultset('Cart')->count, '==', 1,
          "1 cart in the database";

        cmp_ok $cart->dbic_cart->id, '==', $cart->id, "Cart->id is set";

        # get same cart

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                sessions_id => 123456789,
                schema      => $schema,
                plugin      => $plugin,
            );
        }
        "repeat new cart with minimum args lives" or diag explain $trap->read;

        $log = $trap->read->[0];
        cmp_deeply(
            $log,
            superhashof(
                {
                    level   => "debug",
                    message => re(qr/^Existing cart: \d+ main\.$/)
                }
            ),
            'debug: Existing cart: \d+ main.'
        ) or diag explain $log;

        cmp_ok $schema->resultset('Cart')->count, '==', 1,
          "1 cart in the database";

        # new cart with args

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                database    => 'default',
                name        => 'new',
                schema      => $schema,
                sessions_id => 123456789,
                plugin      => $plugin,
              )
        }
        "new cart with database and name";

        $log = $trap->read->[0];
        cmp_deeply(
            $log,
            superhashof(
                {
                    level   => "debug",
                    message => re(qr/^New cart \d+ new\.$/)
                }
            ),
            'debug: New cart \d+ main.'
        ) or diag explain $log;

        cmp_ok $schema->resultset('Cart')->count, '==', 2,
          "2 carts in the database";

        # new cart with args as hashref

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                {
                    database    => 'default',
                    name        => 'hashref',
                    schema      => $schema,
                    sessions_id => 123456789,
                    plugin      => $plugin,
                }
            );
        }
        "new cart with args as hashref";

        $log = $trap->read->[0];
        cmp_deeply(
            $log,
            superhashof(
                {
                    level   => "debug",
                    message => re(qr/^New cart \d+ hashref\.$/)
                }
            ),
            'debug: New cart \d+ hashref.'
        ) or diag explain $log;

        cmp_ok $schema->resultset('Cart')->count, '==', 3,
          "3 carts in the database";

        # add a product to the cart so we can check that it gets reloaded
        # when cart->new is called next time

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                schema      => $schema,
                sessions_id => 123456789,
                plugin      => $plugin,
              )
        }
        "get default cart";

        cmp_ok $schema->resultset('CartProduct')->count, '==', 0,
          "0 cart_products in the database";

        lives_ok { $cart->add('os28085-6') } "add variant os28085-6";

        cmp_ok $schema->resultset('CartProduct')->count, '==', 1,
          "1 cart_product in the database";

        cmp_ok $schema->resultset('Cart')->find( $cart->id )
          ->cart_products->count,
          '==', 1,
          "our cart has 1 product in the database";

        cmp_ok $cart->count, '==', 1, "cart count is 1";

        lives_ok {
            $cart = Dancer2::Plugin::Interchange6::Cart->new(
                schema      => $schema,
                sessions_id => 123456789,
                plugin      => $plugin,
              )
        }
        "refetch the cart";

        cmp_ok $cart->count, '==', 1, "cart count is 1";

        cmp_ok $cart->product_get(0)->sku, 'eq', 'os28085-6',
          "and we have the expected product in the cart";

        # cleanup
        $schema->resultset('Cart')->delete;
    };
}

1;
