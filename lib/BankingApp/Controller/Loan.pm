package BankingApp::Controller::Loan;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::JSON qw(true false);

sub apply ($self) {
  my $user_id = $self->stash('user_id');
  my $req     = $self->req->json;
  my $amount  = $req->{amount};

  unless (defined $amount && $amount =~ /^\d+(?:\.\d{1,2})?$/ && $amount > 0) {
    return $self->render(json => { success => false, error => 'Loan amount must be a positive number with up to 2 decimal places' }, status => 400);
  }

  eval {
    my $loan_id = $self->loans->apply_for_loan($user_id, $amount);
    $self->render(json => {
      success       => true,
      message       => 'Loan application submitted for internal approval',
      loan_id       => $loan_id,
      interest_rate => '5.5%'
    }, status => 201);
  };
  if ($@) {
    # Distinguish validation errors (from model croak) vs internal errors
    if ($@ =~ /Loan amount must be/) {
      return $self->render(json => { success => false, error => "$@" }, status => 400);
    }
    $self->app->log->error($@);
    $self->render(json => { success => false, error => 'Internal server error' }, status => 500);
  }
}

sub list ($self) {
  my $user_id = $self->stash('user_id');

  eval {
    my $loans = $self->loans->get_all_for_user($user_id);
    $self->render(json => { success => true, loans => $loans });
  };
  if ($@) {
    $self->app->log->error($@);
    $self->render(json => { success => false, error => 'Internal server error' }, status => 500);
  }
}

1;
