package Dancer2::Plugin::Interchange6::Routes::Checkout;

use warnings;
use strict;

=head1 NAME

Dancer2::Plugin::Interchange6::Routes::Checkout - Checkout routes for Interchange6 Shop Machine

=head1 DESCRIPTION

This route isn't active by default and B<not recommended>.

=head1 FUNCTIONS

=head2 checkout_route

Returns the checkout route based on the passed routes configuration.

=cut

sub checkout_route {
    my $app = shift;
    my $routes_config = shift;
    my $d2pic6 = $app->with_plugin('Dancer2::Plugin::Interchange6');

    return sub {
        my %values;

        # add stuff useful for cart display
        my $cart = $d2pic6->cart;
        $values{cart_subtotal} = $cart->subtotal;
        $values{cart_total} = $cart->total;
        $values{cart} = $cart->products;

        # call before_checkout_display route so template tokens
        # can be injected
        $app->execute_hook( 'plugin.interchange6.before_checkout_display',
            \%values );

        $app->template( $routes_config->{checkout}->{template}, \%values );
    }
}

1;
