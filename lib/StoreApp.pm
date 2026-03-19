package StoreApp;
use Mojo::Base 'Mojolicious', -signatures;

# This method will run once at server start
sub startup ($self) {

  # Configure the application secrets for security
  $self->secrets(['MySecretPassphrase']);

  # Router
  my $r = $self->routes;

  # Healthcheck / root route
  $r->get('/')->to(cb => sub ($c) {
    $c->render(json => { 
        name => "StoreApp API",
        version => "1.0.0",
        message => "Welcome to the Perl Backend" 
    });
  });

  # --- Users API Routes ---
  my $users = $r->under('/api/users');
  $users->get('/')->to('User#index');
  $users->get('/:id')->to('User#show');
  $users->post('/')->to('User#create');

  # --- Products API Routes ---
  my $products = $r->under('/api/products');
  $products->get('/')->to('Product#index');
}

1;
