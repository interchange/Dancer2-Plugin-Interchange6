package Dancer2::Plugin::Interchange6::Routes::Cart;

use Try::Tiny;

=head1 NAME

Dancer2::Plugin::Interchange6::Routes::Cart - Cart routes for Interchange6 Shop Machine

=cut

=head1 FUNCTIONS

=head2 cart_route

Returns the cart route based on the passed routes configuration.

=cut

sub cart_route {
    my $routes_config = shift;

    return sub {
        my $app = shift;
        my $d2pic6 = $app->with_plugin('Dancer2::Plugin::Interchange6');

        my %values;
        my ($input, $product, $cart, $cart_name, $cart_input,
            $cart_product, $roles, @errors);

        $cart_name = $app->request->param('cart');
        $cart = $cart_name ? $d2pic6->cart($cart_name) : $d2pic6->cart;

        $app->log( "debug", "cart_route cart name: ", $cart->name );

        if ( $app->request->param('remove') ) {

            # removing item from cart

            try {
                $cart->remove( $app->request->param('remove') );
                # if GET then URL now contains ugly query params so redirect
                return $app->redirect('/cart') if $app->request->is_get);
            }
            catch {
                $app->log( "warning", "Cart remove error: $_" );
                push @errors, "Failed to remove product from cart: $_";
            };
        }
        elsif ( $app->request->param('update') && defined $app->request->param('quantity') ) {

            # update existing cart product

            $app->log(
                "debug", "Update ",
                $app->request->param('update'),
                " with quantity ",
                $app->request->param('quantity')
            );

            try {
                $cart->update( $app->request->param('update') =>
                      $app->request->param('quantity') );
            }
            catch {
                $app->log( "warning", "Update cart product error: $_" );
                push @errors, "Failed to update product in cart: $_";
            };
        }

        if ( $input = $app->request->param('sku') ) {

            # add new product

            # we currently only support one product at a time so check that
            # the param is a scalar

            if ( ref($input) eq '' ) {

                $product = $d2pic6->shop_product($input);

                unless ( defined $product ) {
                    $app->log("warning", "sku not found in POST /cart: $input");
                    $app->session->write( shop_cart_error =>
                          { message => "Product not found with sku: $input" } );
                    return $app->redirect('/');
                }

                # store params in hash
                my %params = %{ $app->request->params };

                if ( defined $product->canonical_sku ) {

                    # this is a variant so we need to add in variant info
                    # into %params if missing

                    my $rset = $product->product_attributes->search(
                        {
                            'attribute.type' => 'variant',
                        },
                        {
                            prefetch => [
                                'attribute',
                                {
                                    product_attribute_values =>
                                      'attribute_value'
                                }
                            ],
                        }
                    );
                    while ( my $result = $rset->next ) {
                        my $name  = $result->attribute->name;
                        # WTF! why do we get a resultset of pavs? Surely there
                        # should be only one related pav for pa?
                        my $value = $result->product_attribute_values->first
                          ->attribute_value->value;
                        $params{$name} = $value unless defined $params{$name};

                    }
                }
                # retrieve product attributes for possible variants
                my $attr_ref = $product->attribute_iterator( hashref => 1 );
                my %user_input;

                if ( keys %$attr_ref ) {

                    for my $name ( keys %$attr_ref ) {
                        $user_input{$name} = $params{$name};
                    }

                    $app->log(
                        "debug", "Attributes for $input: ",
                        $attr_ref, ", user input: ",
                        \%user_input
                    );
                    my %match_info;

                    unless ( $cart_product =
                        $product->find_variant( \%user_input, \%match_info ) )
                    {
                        $app->log( "warning", "Variant not found for ",
                            $product->sku );

                        $app->session->write(
                            shop_cart_error => {
                                message => 'Variant not found.',
                                info    => \%match_info
                            }
                        );

                        return $app->redirect( $product->uri );
                    }
                }
                else {
                    # product without variants
                    $cart_product = $product;
                }

                my $quantity = 1;
                if ( $app->request->param('quantity') ) {
                    $quantity = $app->request->param('quantity');
                }

                try {
                    $cart->add(
                        {
                            dbic_product => $cart_product,
                            sku          => $cart_product->sku,
                            quantity     => $quantity
                        }
                    );
                }
                catch {
                    $app->log( "warning", "Cart add error: $_" );
                    push @errors, "Failed to add product to cart: $_";
                };
            }
        }

        # add stuff useful for cart display
        $values{cart_subtotal} = $cart->subtotal;
        $values{cart_total} = $cart->total;
        $values{cart} = $cart->products;
        $values{cart_error} = join(". ", @errors) if scalar @errors;

        # call before_cart_display route so template tokens
        # can be injected
        $app->execute_hook('plugin.interchange6.before_cart_display', \%values);

        $app->template( $routes_config->{cart}->{template}, \%values );
    }
}

1;
