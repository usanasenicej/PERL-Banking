package StoreApp::Controller::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# In-memory mock database for users
my @USERS = (
    { id => 1, name => 'Alice', role => 'Admin' },
    { id => 2, name => 'Bob', role => 'Customer' },
    { id => 3, name => 'Charlie', role => 'Manager' }
);

# GET /api/users
sub index ($self) {
  $self->render(json => { users => \@USERS });
}

# GET /api/users/:id
sub show ($self) {
  my $id = $self->stash('id');
  
  # Find user by ID
  my ($user) = grep { $_->{id} == $id } @USERS;
  
  if ($user) {
    $self->render(json => $user);
  } else {
    $self->render(json => { error => 'User not found' }, status => 404);
  }
}

# POST /api/users
sub create ($self) {
  my $json = $self->req->json;
  
  if ($json && $json->{name}) {
      my $new_id = @USERS + 1;
      my $new_user = {
          id   => $new_id,
          name => $json->{name},
          role => $json->{role} // 'Customer'
      };
      
      push @USERS, $new_user;
      
      $self->render(json => $new_user, status => 201);
  } else {
      $self->render(json => { error => 'Missing required field: name' }, status => 400);
  }
}

1;
