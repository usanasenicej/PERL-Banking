package BankingApp;
use Mojo::Base 'Mojolicious', -signatures;

use Mojo::SQLite;
use Mojo::JWT;
use BankingApp::Model::Users;
use BankingApp::Model::Accounts;
use BankingApp::Model::Transactions;
use BankingApp::Model::Loans;

sub startup ($self) {
  # Load configuration
  my $config = $self->plugin('Config', {file => 'banking_app.conf'});
  $self->secrets($config->{secrets});

  # Connect to SQLite database
  $self->helper(sqlite => sub { state $sql = Mojo::SQLite->new($config->{sqlite_url}) });

  # Run DB migrations
  $self->sqlite->migrations->name('banking')->from_file($self->home->child('migrations/001_initial.sql'))->migrate;

  # Initialize model layers as helpers for Dependency Injection
  $self->helper(users        => sub ($c) { state $users = BankingApp::Model::Users->new(sqlite        => $c->sqlite) });
  $self->helper(accounts     => sub ($c) { state $accts = BankingApp::Model::Accounts->new(sqlite     => $c->sqlite) });
  $self->helper(transactions => sub ($c) { state $tx    = BankingApp::Model::Transactions->new(sqlite => $c->sqlite) });
  $self->helper(loans        => sub ($c) { state $loans = BankingApp::Model::Loans->new(sqlite        => $c->sqlite) });

  $self->helper(jwt_secret => sub { $config->{jwt_secret} });

  # -------------------------------------------------------
  # Security headers — applied to every response
  # -------------------------------------------------------
  $self->hook(before_dispatch => sub ($c) {
    $c->res->headers->header('X-Content-Type-Options' => 'nosniff');
    $c->res->headers->header('X-Frame-Options'        => 'DENY');
    $c->res->headers->header('X-XSS-Protection'       => '1; mode=block');
    $c->res->headers->header('Referrer-Policy'         => 'no-referrer');
  });

  # -------------------------------------------------------
  # Per-IP in-memory rate limiter (auth endpoints)
  # -------------------------------------------------------
  my %_rate_store;
  my $RATE_LIMIT  = $config->{rate_limit} // 10;
  my $RATE_WINDOW = 60;

  $self->helper(check_rate_limit => sub ($c) {
    my $ip    = $c->tx->remote_address // '0.0.0.0';
    my $now   = time;
    my $entry = $_rate_store{$ip} //= { count => 0, reset_at => $now + $RATE_WINDOW };
    if ($now >= $entry->{reset_at}) {
      $entry->{count}    = 0;
      $entry->{reset_at} = $now + $RATE_WINDOW;
    }
    $entry->{count}++;
    return $entry->{count} <= $RATE_LIMIT;
  });

  # -------------------------------------------------------
  # JWT authentication helper — used by protected pipelines
  # -------------------------------------------------------
  $self->helper(authenticate => sub ($c) {
    my $auth_header = $c->req->headers->authorization;
    unless ($auth_header && $auth_header =~ /^Bearer\s+(.+)$/) {
      $c->render(json => { error => 'Missing or invalid Authorization header' }, status => 401);
      return undef;
    }

    my $token  = $1;
    my $jwt    = Mojo::JWT->new(secret => $c->jwt_secret);
    my $claims;
    eval { $claims = $jwt->decode($token) };

    if ($@) {
      my $reason = $@ =~ /expir/i ? 'Token has expired' : 'Invalid JWT token';
      $c->app->log->debug("JWT rejected: $@");
      $c->render(json => { error => $reason }, status => 401);
      return undef;
    }

    unless ($claims) {
      $c->render(json => { error => 'Invalid or empty JWT claims' }, status => 401);
      return undef;
    }

    $c->stash(user_id => $claims->{user_id});
    return 1;
  });

  my $r = $self->routes;

  # -------------------------------------------------------
  # Rate-limited public auth pipeline
  # -------------------------------------------------------
  my $public_auth = $r->under('/api/auth' => sub ($c) {
    unless ($c->check_rate_limit) {
      $c->render(json => { error => 'Too many requests. Please wait a moment and try again.' }, status => 429);
      return undef;
    }
    return 1;
  });

  # Public routes (Authentication)
  $public_auth->post('/register')->to('Auth#register');
  $public_auth->post('/login')->to('Auth#login');

  # -------------------------------------------------------
  # Protected route pipeline
  # -------------------------------------------------------
  my $api = $r->under('/api' => sub ($c) { $c->authenticate });

  # Profile routes (also rate-limited for the PATCH)
  $api->get('/auth/me')->to('Auth#me');
  $api->patch('/auth/me')->to('Auth#update_profile');

  # Account routes
  $api->get('/accounts')->to('Account#list_accounts');
  $api->post('/accounts')->to('Account#create_account');
  $api->get('/accounts/:account_id')->to('Account#get_account');
  $api->delete('/accounts/:account_id')->to('Account#delete_account');
  $api->get('/accounts/:account_id/summary')->to('Transaction#summary');

  # Transaction routes
  $api->post('/transactions/deposit')->to('Transaction#deposit');
  $api->post('/transactions/withdraw')->to('Transaction#withdraw');
  $api->post('/transactions/transfer')->to('Transaction#transfer');
  $api->get('/accounts/:account_id/transactions')->to('Transaction#history');

  # Loan routes
  $api->post('/loans/apply')->to('Loan#apply');
  $api->get('/loans')->to('Loan#list');
  $api->get('/loans/:loan_id')->to('Loan#get_loan');
  $api->post('/loans/:loan_id/repay')->to('Loan#repay');
}

1;
