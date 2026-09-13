package BankingApp::Model::Loans;
use Mojo::Base -base, -signatures;
use Carp qw(croak);

has 'sqlite';

# Configuration constants
use constant {
    DEFAULT_INTEREST_RATE => 5.50,
    STATUS_PENDING        => 'pending',
    MIN_LOAN_AMOUNT       => 100,
    MAX_LOAN_AMOUNT       => 1_000_000,
};

sub apply_for_loan ($self, $user_id, $amount) {

    croak "User ID is required"
        unless defined $user_id;

    croak "Loan amount must be between " . MIN_LOAN_AMOUNT . " and " . MAX_LOAN_AMOUNT
        unless defined $amount
        && $amount =~ /^\d+(?:\.\d+)?$/
        && $amount >= MIN_LOAN_AMOUNT
        && $amount <= MAX_LOAN_AMOUNT;

    my $db = $self->sqlite->db;

    my $loan = {
        user_id       => $user_id,
        amount        => $amount,
        interest_rate => DEFAULT_INTEREST_RATE,
        status        => STATUS_PENDING,
    };

    my $result = eval { $db->insert('loans', $loan) };
    croak "Failed to create loan: $@" if $@;

    return $result->last_insert_id;
}

sub get_all_for_user ($self, $user_id) {

    croak "User ID is required"
        unless defined $user_id;

    my $db = $self->sqlite->db;

    return $db->select(
        'loans',
        '*',
        { user_id => $user_id },
        { order_by => { -desc => 'created_at' } }
    )->hashes->to_array;
}

sub get_by_id_and_user ($self, $loan_id, $user_id) {
    croak "Loan ID and User ID are required"
        unless defined $loan_id && defined $user_id;

    my $db = $self->sqlite->db;
    return $db->select('loans', '*', { id => $loan_id, user_id => $user_id })->hash;
}

sub repay ($self, $loan_id, $user_id) {
    croak "Loan ID and User ID are required"
        unless defined $loan_id && defined $user_id;

    my $db = $self->sqlite->db;

    # Only allow repayment of pending/approved loans
    my $loan = $db->select('loans', '*', { id => $loan_id, user_id => $user_id })->hash;
    croak "Loan not found" unless $loan;
    croak "Loan is already repaid" if $loan->{status} eq 'repaid';

    $db->update('loans',
        { status => 'repaid', repaid_at => \"CURRENT_TIMESTAMP" },
        { id => $loan_id, user_id => $user_id }
    );
    return 1;
}

1;
