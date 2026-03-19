package BankingApp::Controller::Loan;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub apply ($self) {
  my $user_id = $self->stash('user_id');
  my $req = $self->req->json;
  my $amount = $req->{amount};
  
  if (!$amount || $amount <= 0) {
    return $self->render(json => { error => 'Invalid loan application amount' }, status => 400);
  }

  my $loan_id = $self->loans->apply_for_loan($user_id, $amount);
  
  $self->render(json => { 
    message => 'Loan application submitted for internal approval', 
    loan_id => $loan_id,
    interest_rate => "5.5%"
  }, status => 201);
}

sub list ($self) {
  my $user_id = $self->stash('user_id');
  my $loans = $self->loans->get_all_for_user($user_id);
  
  $self->render(json => { loans => $loans });
}

1;
