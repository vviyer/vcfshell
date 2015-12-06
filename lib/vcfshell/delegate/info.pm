package vcfshell::delegate::info;
use strict;

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

return 1;
