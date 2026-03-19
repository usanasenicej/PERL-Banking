package BankingApp;
use Mojo::Base 'Mojolicious', -signatures;

use Mojo::SQLite;
use BankingApp::Model::Users;
use BankingApp::Model::Accounts;
use BankingApp::Model::Transactions;

sub startup ($self) {
  # Load configuration
  my $config = $self->plugin('Config', {file => 'banking_app.conf'});
  $self->secrets($config->{secrets});

  # Connect to SQLite database
  $self->helper(sqlite => sub { state $sql = Mojo::SQLite->new($config->{sqlite_url}) });
  
  # Run DB migrations
  $self->sqlite->migrations->name('banking')->from_file($self->home->child('migrations/001_initial.sql'))->migrate;

  # Initialize model layers as helpers for Dependency Injection
  $self->helper(users => sub ($c) { state $users = BankingApp::Model::Users->new(sqlite => $c->sqlite) });
  $self->helper(accounts => sub ($c) { state $accounts = BankingApp::Model::Accounts->new(sqlite => $c->sqlite) });
  $self->helper(transactions => sub ($c) { state $tx = BankingApp::Model::Transactions->new(sqlite => $c->sqlite) });

  $self->helper(jwt_secret => sub { $config->{jwt_secret} });

  my $r = $self->routes;

  # Public Routes (Authentication)
  $r->post('/api/auth/register')->to('Auth#register');
  $r->post('/api/auth/login')->to('Auth#login');

  # Protected Route Pipeline
  my $api = $r->under('/api' => sub ($c) {
    my $auth_header = $c->req->headers->authorization;
    unless ($auth_header && $auth_header =~ /^Bearer\s+(.+)$/) {
      $c->render(json => { error => 'Missing or invalid Authorization header' }, status => 401);
      return undef;
    }
    
    my $token = $1;
    require Mojo::JWT;
    my $jwt = Mojo::JWT->new(secret => $c->jwt_secret);
    
    my $claims;
    eval { $claims = $jwt->decode($token) };
    
    if ($@ || !$claims) {
      $c->render(json => { error => 'Invalid or expired JWT token' }, status => 401);
      return undef;
    }
    
    # Authenticated user is injected into stash context
    $c->stash(user_id => $claims->{user_id});
    return 1;
  });

  # Account Scoped Routes
  $api->get('/accounts')->to('Account#list_accounts');
  $api->post('/accounts')->to('Account#create_account');
  $api->get('/accounts/:account_id')->to('Account#get_account');

  # Transactional Logic Routes
  $api->post('/transactions/deposit')->to('Transaction#deposit');
  $api->post('/transactions/withdraw')->to('Transaction#withdraw');
  $api->post('/transactions/transfer')->to('Transaction#transfer');
  $api->get('/accounts/:account_id/transactions')->to('Transaction#history');
}

1;
