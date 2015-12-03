package vcfshell::delegate::info;
use strict;
use Log4Perl qw (:easy);

sub new
{
    my $class = shift;
    my $self = {
        _config => shift,
    };
    # Print all the values just for clarification.
    bless $self, $class;
    return $self;
}

sub config {
	my ($self) = shift;
	return $self->{_config};
}

sub trigger {
	my $self = shift;
	return "INFO";
}
