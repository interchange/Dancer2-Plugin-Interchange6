package Dancer2::Plugin::Interchange6::Routes::Checkout;

use Dancer2::Plugin;
use Dancer2::Plugin::Interchange6 ();

=head1 NAME

Dancer2::Plugin::Interchange6::Routes::Checkout - Checkout routes for Interchange6 Shop Machine

=cut

plugin_hooks 'before_checkout_display';

=head1 DESCRIPTION

This route isn't active by default and B<not recommended>.

=head1 FUNCTIONS

=head2 checkout_route

Returns the checkout route based on the passed routes configuration.

=cut

sub checkout_route {
    my $routes_config = shift;

    return sub {
        my %values;

        # add stuff useful for cart display
        $values{cart} = cart->products;
        $values{cart_subtotal} = cart->subtotal;
        $values{cart_total} = cart->total;

        # call before_checkout_display route so template tokens
        # can be injected
        execute_hook('before_checkout_display', \%values);
        template $routes_config->{checkout}->{template}, \%values;
    }
}

sub BUILD {
    my $plugin = shift;

    $plugin->app->add_hook( 
        Dancer2::Core::Hook->new(
            name => 'after',
            code => sub {
                $plugin->app->execute_hook( 'plugin.interchange6_routes_cart.before_checkout_display' );
            },
        ) );
}

1;
