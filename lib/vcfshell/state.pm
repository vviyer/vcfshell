=head1 NAME                    

vcfshell::state
  
=head1 DESCRIPTION
  
A information carrying the session state:
- the working vcf file 
- which samples to print, 
- which format fields to show 
- which info fields to show.

This should get _set_ by the "samples", "info" and "format" commands, and read by the loc command to prepare the tabular output

THE instance of this class is handed back and forth to the command delegate (info, format, chrom) when they 'handle_command' the user commands
  
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

package vcfshell::state;
use strict;
use Log::Log4perl qw(get_logger);
my $logger = get_logger("vcfshell::state");

sub new
{
    my $class = shift;
    my $self = {
        _config => shift,
    };
    # Print all the values just for clarification.
    bless $self, $class;
    $self->{_samples} = [];
    $self->{_format} = {};
    $self->{_info} = {};
    $self->{_vcf_file} = [];
    return $self;
}

sub config {
	my ($self) = shift;
	return $self->{_config};
}

sub format {
	my $self = shift;
	my $arg = shift;
	if($arg){
		$self->{_format} = $arg;
	}
	return $self->{_format};
}

sub info {
	my $self = shift;
	my $arg = shift;
	if($arg){
		$self->{_info} = $arg;
	}
	return $self->{_info};
}

sub samples {
	my $self = shift;
	my $arg = shift;
	if($arg){
		$self->{_samples} = $arg;
	}
	return $self->{_samples};
}

sub vcf_file {
	my $self = shift;
	my $arg = shift;
	if($arg){
		$self->{_vcf_file} = $arg;
	}
	return $self->{_vcf_file};
}

return 1;
