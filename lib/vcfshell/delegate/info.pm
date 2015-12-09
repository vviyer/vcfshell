=head1 NAME                    

vcfshell::delegate::info
  
=head1 DESCRIPTION
  
  
=head1 AUTHOR
  
Vivek Iyer <vvi@sanger.ac.uk
  
=head1 COPYRIGHT AND LICENSE   
  
Copyright (c) 2015 Genome Research Limited.
  
This file is part of vcfshell.
  
vcfshell is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.
  
This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.
  
You should have received a copy of the GNU General Public License along with
this program. If not, see L<http://www.gnu.org/licenses/>.
  
=cut

package vcfshell::delegate::info;
use strict;
use Log::Log4perl qw(get_logger);
my $logger = get_logger("vcfshell::delegate::info");

my $infos = [];

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

sub handle_command {
	my $self = shift;
	my $command = shift;
	return undef;
}

sub handle_header_line {
	my $self = shift;
	my $line = shift;
}

sub header_trigger {
	my $self = shift;
	return "^##INFO";
}

sub infos {
	my ($self) = @_;
	return $self->{_infos};
}

return 1;
