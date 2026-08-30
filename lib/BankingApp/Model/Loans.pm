package BankingApp::Model::Loans;
use Mojo::Base -base, -signatures;
use Carp qw(croak);

has 'sqlite';

# Configuration constants
use constant {
    DEFAULT_INTEREST_RATE => 5.50,
    STATUS_PENDING        => 'pending',
};

sub apply_for_loan ($self, $user_id, $amount) {

    # Validation
    croak "User ID is required"
        unless defined $user_id;

    croak "Loan amount must be greater than zero"
        unless defined $amount
        && $amount =~ /^\d+(?:\.\d+)?$/
        && $amount > 0;

    my $db = $self->sqlite->db;

    my $loan = {
        user_id       => $user_id,
        amount        => $amount,
        interest_rate => DEFAULT_INTEREST_RATE,
        status        => STATUS_PENDING,
    };

    my $tx = eval { $db->insert('loans', $loan) };

    croak "Failed to create loan: $@" if $@;

    return $tx->last_insert_id;
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
sub get_active_loans () { return ->{sqlite}->db->query('SELECT * FROM loans WHERE status = ''approved''')->hashes->to_array; }

