package BankingApp::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Crypt::Bcrypt qw(bcrypt_hash);
use Mojo::JWT;

sub register ($self) {
  my $json = $self->req->json;
  
  if (!$json || !$json->{username} || !$json->{password} || !$json->{email}) {
      return $self->render(json => { error => 'Missing username, password or email' }, status => 400);
  }

  my $salt = "0123456789012345"; 
  my $hash = bcrypt_hash({ key_nul => 1, cost => 8, salt => $salt }, $json->{password});

  my $id = $self->users->add($json->{username}, $hash, $json->{email});
  
  if ($id) {
    $self->render(json => { message => 'User registered successfully', id => $id }, status => 201);
  } else {
    $self->render(json => { error => 'Username or email already exists' }, status => 409);
  }
}

sub login ($self) {
  my $json = $self->req->json;

  if (!$json || !$json->{username} || !$json->{password}) {
      return $self->render(json => { error => 'Missing username or password' }, status => 400);
  }

  my $user = $self->users->verify($json->{username});
  if (!$user) {
    return $self->render(json => { error => 'Invalid credentials' }, status => 401);
  }

  my $salt = "0123456789012345";
  my $hash = bcrypt_hash({ key_nul => 1, cost => 8, salt => $salt }, $json->{password});

  if ($hash eq $user->{password_hash}) {
    # Generate JWT
    my $jwt = Mojo::JWT->new(
      secret => $self->jwt_secret,
      claims => { user_id => $user->{id}, exp => time + 3600 }
    );
    my $token = $jwt->encode;
    
    $self->render(json => { token => $token });
  } else {
    $self->render(json => { error => 'Invalid credentials' }, status => 401);
  }
}

sub me ($self) {
  my $user_id = $self->stash('user_id');
  my $user = $self->users->get_by_id($user_id);
  
  if ($user) {
    $self->render(json => { profile => $user });
  } else {
    $self->render(json => { error => 'User profile not found' }, status => 404);
  }
}

1;
