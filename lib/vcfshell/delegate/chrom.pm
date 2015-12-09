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
use Log::Log4perl qw(get_logger);
my $logger = get_logger("vcfshell::delegate::chrom");

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


=head2 NAME                    
handle_command
=cut
sub handle_command {
	my ($self, $state, $command, @args) = @_;
	$logger->debug("state $state, command $command, args @args");
	if($command eq 'samples'){
		$logger->debug("args @args");
		# If you have no extra sample args, then just return a string of all samples
		my $output = "";
		if(!@args){
			$output = $self->truncate_for_output_if_needed(@{$self->samples}); 
		}else{
			$state->samples(\@args);
			$output = $self->truncate_for_output_if_needed(@args); 
			$output .= " ok";
		}
		$logger->debug("returning $output");
		return $output;
	}
}

sub handle_header_line {
	my $self = shift;
	my $line = shift;
	my $state = shift;
	my @parts = split /\t/,$line;
	my $samples_started = 0;
	$logger->debug("handing header line $line");
	foreach my $part (@parts){
		if($samples_started){
			push(@{$self->samples}, $part)
		}
		if($part eq 'FORMAT'){
			$samples_started = 1;
		}
	}
	my @samples = @{$self->samples};
	$logger->debug("handled header line, samples @samples");
	$state->samples($self->samples);
}

sub header_trigger {
	my $self = shift;
	return "^#CHROM";
}

sub samples {
	my ($self,$arg) = @_;
	if($arg){
		$self->{_samples} = $arg;
	}
	return $self->{_samples};
}

sub truncate_for_output_if_needed {
	my ($self, @input) = @_;
	my $trunced_output = "";
	my $size = scalar(@input);
	if($size > 4){
		$logger->debug("truncating input");
		return $input[0]." ".$input[1]." ".$input[2]." ... ".$input[scalar(@input)-1] . " ($size)";
	}else{
		$logger->debug("not truncating @input");
		return join " ",@input;
	}
}

return 1;
