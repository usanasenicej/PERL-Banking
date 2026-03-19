package StoreApp::Controller::Product;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# In-memory mock products
my @PRODUCTS = (
    { id => 101, name => 'Laptop', price => 1200.00 },
    { id => 102, name => 'Wireless Mouse', price => 25.50 },
    { id => 103, name => 'Mechanical Keyboard', price => 85.00 }
);

# GET /api/products
sub index ($self) {
  $self->render(json => { products => \@PRODUCTS });
}

1;
