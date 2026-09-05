package BankingApp::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Crypt::Bcrypt qw(bcrypt_hash);
use Mojo::JWT;
use MIME::Base64 qw(encode_base64 decode_base64);

sub register ($self) {
  my $json = $self->req->json;

  if (!$json || !$json->{username} || !$json->{password} || !$json->{email}) {
      return $self->render(json => { success => \0, error => 'Missing username, password or email' }, status => 400);
  }

  # Username: 3–32 chars, alphanumeric + underscore only
  if ($json->{username} !~ /^\w{3,32}$/) {
      return $self->render(json => { success => \0, error => 'Username must be 3–32 characters (letters, numbers, underscores only)' }, status => 400);
  }

  # Basic email format check
  if ($json->{email} !~ /^[^@\s]+\@[^@\s]+\.[^@\s]+$/) {
      return $self->render(json => { success => \0, error => 'Invalid email address' }, status => 400);
  }

  # Password: at least 8 chars, must contain a digit
  if (length($json->{password}) < 8 || $json->{password} !~ /\d/) {
      return $self->render(json => { success => \0, error => 'Password must be at least 8 characters long and contain a number' }, status => 400);
  }

  my $salt = join('', map { chr(rand(256)) } 1..16);
  my $hash = bcrypt_hash({ key_nul => 1, cost => 8, salt => $salt }, $json->{password});
  my $stored_hash = encode_base64($salt, '') . ':' . encode_base64($hash, '');

  eval {
    my $id = $self->users->add($json->{username}, $stored_hash, $json->{email});
    if ($id) {
      $self->render(json => { success => \1, message => 'User registered successfully', id => $id }, status => 201);
    } else {
      $self->render(json => { success => \0, error => 'Username or email already exists' }, status => 409);
    }
  };
  if ($@) {
    $self->app->log->error($@);
    $self->render(json => { success => \0, error => 'Internal server error' }, status => 500);
  }
}

sub login ($self) {
  my $json = $self->req->json;

  if (!$json || !$json->{username} || !$json->{password}) {
      return $self->render(json => { success => \0, error => 'Missing username or password' }, status => 400);
  }

  my $user = $self->users->verify($json->{username});
  if (!$user) {
    return $self->render(json => { success => \0, error => 'Invalid credentials' }, status => 401);
  }

  my ($salt_b64, $hash_b64) = split /:/, $user->{password_hash};

  if (!$salt_b64 || !$hash_b64) {
    return $self->render(json => { success => \0, error => 'Legacy user format, please re-register' }, status => 401);
  }

  my $salt = decode_base64($salt_b64);
  my $hash = bcrypt_hash({ key_nul => 1, cost => 8, salt => $salt }, $json->{password});

  if ($hash eq decode_base64($hash_b64)) {
    my $jwt = Mojo::JWT->new(
      secret => $self->jwt_secret,
      claims => { user_id => $user->{id}, exp => time + 3600 }
    );
    my $token = $jwt->encode;
    $self->render(json => { success => \1, token => $token });
  } else {
    $self->render(json => { success => \0, error => 'Invalid credentials' }, status => 401);
  }
}

sub me ($self) {
  my $user_id = $self->stash('user_id');
  my $user    = $self->users->get_by_id($user_id);

  if ($user) {
    $self->render(json => { success => \1, profile => $user });
  } else {
    $self->render(json => { success => \0, error => 'User profile not found' }, status => 404);
  }
}

1;
