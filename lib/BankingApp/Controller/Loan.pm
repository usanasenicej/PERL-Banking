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

# GET /loans/:loan_id
sub get_loan ($self) {
  my $user_id = $self->stash('user_id');
  my $loan_id = $self->param('loan_id');

  unless (defined $loan_id && $loan_id =~ /^\d+$/) {
    return $self->render(json => { success => false, error => 'Invalid loan ID' }, status => 400);
  }

  eval {
    my $loan = $self->loans->get_by_id_and_user($loan_id, $user_id);
    unless ($loan) {
      return $self->render(json => { success => false, error => 'Loan not found' }, status => 404);
    }
    $self->render(json => { success => true, loan => $loan });
  };
  if ($@) {
    $self->app->log->error($@);
    $self->render(json => { success => false, error => 'Internal server error' }, status => 500);
  }
}

# POST /loans/:loan_id/repay
sub repay ($self) {
  my $user_id = $self->stash('user_id');
  my $loan_id = $self->param('loan_id');

  unless (defined $loan_id && $loan_id =~ /^\d+$/) {
    return $self->render(json => { success => false, error => 'Invalid loan ID' }, status => 400);
  }

  eval {
    $self->loans->repay($loan_id, $user_id);
    $self->render(json => { success => true, message => 'Loan marked as repaid' });
  };
  if ($@) {
    if ($@ =~ /already repaid/) {
      return $self->render(json => { success => false, error => 'Loan is already repaid' }, status => 409);
    }
    if ($@ =~ /not found/) {
      return $self->render(json => { success => false, error => 'Loan not found' }, status => 404);
    }
    $self->app->log->error($@);
    $self->render(json => { success => false, error => 'Internal server error' }, status => 500);
  }
}

1;
