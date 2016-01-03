package Dancer2::Plugin::Interchange6::Routes::Cart;

use Dancer2::Plugin;
use Dancer2::Plugin::Interchange6;

=head1 NAME

Dancer2::Plugin::Interchange6::Routes::Cart - Cart routes for Interchange6 Shop Machine

=cut

plugin_hooks 'before_cart_display';

=head1 FUNCTIONS

=head2 cart_route

Returns the cart route based on the passed routes configuration.

=cut

sub cart_route {
    my $app = shift;
    my $routes_config = shift;

    return sub {
        my %values;
        my ($input, $product, $cart, $cart_item, $cart_name, $cart_input,
            $cart_product);

        if ($cart_name = $app->request->param('cart') && scalar($cart_name)) {
            $cart = cart($cart_name);
        }
        else {
            $cart = cart;
        }

        $app->log('debug', "cart_route cart name: " . $cart->name);

	if ($app->request->param('remove')) {
	    # removing item from cart
	    $cart->remove($app->request->param('remove'));
	}

        if ($input = $app->request->param('sku')) {
            if (scalar($input)) {
                $product = shop_product($input);

                # retrieve product attributes for possible variants
                my $attr_ref = $product->attribute_iterator(hashref => 1);
                my %user_input;

                if (keys %$attr_ref) {
                    # find variant
                    for my $name (keys %$attr_ref) {
                        $user_input{$name} = param($name);
                    }

                    $app->log('debug', "Attributes for $input: ", $attr_ref, ", user input: ", \%user_input);
                    my %match_info;

                    unless ($cart_product = $product->find_variant(\%user_input, \%match_info)) {
                        $app->log('warning', "Variant not found for ", $product->sku);
                        $app->session->write(shop_cart_error => {message => 'Variant not found.', info => \%match_info});
                        return $app->redirect($product->uri);
                    };
                }
                else {
                    # product without variants
                    $cart_product = $product;
                }

                $cart_input = {sku => $cart_product->sku,
                               name => $cart_product->name,
                               price => $cart_product->price};

		if (param('quantity')) {
		    $cart_input->{quantity} = param('quantity');
		}

                $app->log('debug', "Cart input: ", $cart_input);

                $cart_item = $cart->add($cart_input);

                unless ($cart_item) {
                    $app->log('warning', "Cart error: ", $cart->error);
                    $values{cart_error} = $cart->error;
                }
            }
        }

        # add stuff useful for cart display
        $values{cart} = $cart->get_products;
        $values{cart_subtotal} = $cart->subtotal;
        $values{cart_total} = $cart->total;

        # call before_cart_display route so template tokens
        # can be injected
        $app->execute_hook(
            'plugin.interchange6_routes_cart.before_cart_display', \%values);

        $app->template($routes_config->{cart}->{template}, \%values);
    }
}

sub BUILD {
    my $plugin = shift;

    return;
    
    $plugin->app->add_hook( 
        Dancer2::Core::Hook->new(
            name => 'after',
            code => sub {
                $plugin->app->execute_hook( 'plugin.interchange6_routes_cart.before_cart_display' );
            },
        ) );
}

1;
