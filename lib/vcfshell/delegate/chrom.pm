=head1 NAME                    

vcfshell::delegate::chrom
  
=head1 DESCRIPTION
  
Handler for the CHROM field. 
This should parse out lines starting with CHROM and 
- isolate a list of samples
- hold the list in an array present on this instance.

  
=head1 AUTHOR
  
Vivek Iyer <vvi@sanger.ac.uk>
  
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

package vcfshell::delegate::chrom;
use strict;

sub new
{
    my $class = shift;
    my $self = {
        _config => shift,
    };
    # Print all the values just for clarification.
    bless $self, $class;
    $self->{_samples} = [];
    return $self;
}

sub config {
	my ($self) = shift;
	return $self->{_config};
}

sub header_trigger {
	my $self = shift;
	return "^#CHROM";
}

sub handle_line {
	my $self = shift;
	my $line = shift;
	my @parts = split /\t/,$line;
	my $samples_started = 0;
	foreach my $part (@parts){
		if($samples_started){
			push(@{$self->samples}, $part)
		}
		if($part eq 'FORMAT'){
			$samples_started = 1;
		}
	}
}

sub samples {
	my $self = shift;
	return $self->{_samples};
}

return 1;
