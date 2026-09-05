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
        { user_id => $user_id }
    )->hashes->to_array;
}

1;
