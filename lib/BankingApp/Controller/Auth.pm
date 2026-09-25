package BankingApp::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Crypt::Bcrypt qw(bcrypt bcrypt_check);
use Mojo::JWT;
use MIME::Base64 qw(encode_base64 decode_base64);

# Cost factor for bcrypt — minimum 10 for production (was 8, now 12)
use constant BCRYPT_COST => 12;

# -------------------------------------------------------
# Private helpers
# -------------------------------------------------------

# Hash a plaintext password; returns the storable "salt_b64:hash_b64" string.
sub _hash_password ($plaintext) {
  my $salt = join('', map { chr(int(rand(256))) } 1..16);
  my $hash = bcrypt({ key_nul => 1, cost => BCRYPT_COST, salt => $salt }, $plaintext);
  return encode_base64($salt, '') . ':' . encode_base64($hash, '');
}

# Constant-time password verification.  Returns 1 if correct, 0 otherwise.
sub _verify_password ($stored, $candidate) {
  my ($salt_b64, $hash_b64) = split /:/, $stored, 2;
  return 0 unless $salt_b64 && $hash_b64;

  my $salt         = decode_base64($salt_b64);
  my $expected     = decode_base64($hash_b64);
  my $actual       = bcrypt({ key_nul => 1, cost => BCRYPT_COST, salt => $salt }, $candidate);

  # Constant-time comparison — mitigates timing attacks
  return 0 unless length($actual) == length($expected);
  my $diff = 0;
  $diff |= ord(substr($actual, $_, 1)) ^ ord(substr($expected, $_, 1))
    for 0 .. length($actual) - 1;
  return $diff == 0 ? 1 : 0;
}

# -------------------------------------------------------
# Public actions
# -------------------------------------------------------

sub register ($self) {
  my $json = $self->req->json;

  unless ($json && $json->{username} && $json->{password} && $json->{email}) {
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

  my $stored_hash = _hash_password($json->{password});

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

  unless ($json && $json->{username} && $json->{password}) {
    return $self->render(json => { success => \0, error => 'Missing username or password' }, status => 400);
  }

  my $user = $self->users->verify($json->{username});

  # Use the same generic message for missing user or wrong password (no user enumeration)
  unless ($user && _verify_password($user->{password_hash}, $json->{password})) {
    return $self->render(json => { success => \0, error => 'Invalid credentials' }, status => 401);
  }

  my $jwt   = Mojo::JWT->new(
    secret => $self->jwt_secret,
    claims => { user_id => $user->{id}, exp => time + 3600 }
  );
  my $token = $jwt->encode;
  $self->render(json => { success => \1, token => $token });
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

# PATCH /api/auth/me — update email or password
sub update_profile ($self) {
  my $user_id = $self->stash('user_id');
  my $json    = $self->req->json || {};

  my $changed = 0;

  # Update email if provided
  if (my $new_email = $json->{email}) {
    if ($new_email !~ /^[^@\s]+\@[^@\s]+\.[^@\s]+$/) {
      return $self->render(json => { success => \0, error => 'Invalid email address' }, status => 400);
    }
    $self->users->update_email($user_id, $new_email);
    $changed++;
  }

  # Update password if provided — requires current_password verification
  if (my $new_pass = $json->{new_password}) {
    my $current_pass = $json->{current_password};
    unless ($current_pass) {
      return $self->render(json => { success => \0, error => 'current_password is required to change password' }, status => 400);
    }

    if (length($new_pass) < 8 || $new_pass !~ /\d/) {
      return $self->render(json => { success => \0, error => 'New password must be at least 8 characters and contain a number' }, status => 400);
    }

    # Fetch current hash directly from DB (get_by_id omits password_hash for safety)
    my $full = $self->sqlite->db->select('users', ['password_hash'], { id => $user_id })->hash;

    unless (_verify_password($full->{password_hash}, $current_pass)) {
      return $self->render(json => { success => \0, error => 'Current password is incorrect' }, status => 401);
    }

    $self->users->update_password($user_id, _hash_password($new_pass));
    $changed++;
  }

  unless ($changed) {
    return $self->render(json => { success => \0, error => 'No fields to update. Provide email and/or new_password + current_password' }, status => 400);
  }

  $self->render(json => { success => \1, message => 'Profile updated successfully' });
}

1;
