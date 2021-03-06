=head1 NAME                    

vcfshell::delegate::format
  
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

package vcfshell::delegate::format;
use strict;
use Log::Log4perl qw(get_logger);
use Data::Dumper;
my $logger = get_logger("vcfshell::delegate::format");

sub new
{
    my $class = shift;
    my $self = {
        _config => shift,
    };
    # Print all the values just for clarification.
    bless $self, $class;
    $self->{_format} = {};
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

=head2 NAME                    
handle_command

=head2 DESCRIPTION
If no args passed in, return a list of formats & descriptions to the screen (derived from header line)

If a list of args are passed in, assume restrict the formats to be displayed and store them in the state.

If the only arg passed in is 'reset' then reset the format list in the session state to be the full initial list.
=cut
sub handle_command {
	my ($self, $state, $command, @args) = @_;
	if($command eq 'format'){
		# If you have no extra sample args, then just return a string of all format fields and descriptions 
		my $output = "";
		if(!scalar(@args)){
			my $output_format = "%-15s%-15s\n";
			foreach my $key (keys %{$state->format}){
				my $desc = $state->format->{$key};
				$logger->debug("FORMAT command $key $desc");
				$output .= sprintf($output_format,$key,$desc);
			}
		}else{
			# Here we've been given a list of keys, so we have to make a new hash with the key-subset 
			# However if the argument is 'reset' then set the format state back to the original 
			if((scalar(@args)==1) && ($args[0] eq 'reset')){
				$state->format($self->format);
				$output = "format keys reset";
			}else{
				my $tmp_hash = {};
				foreach my $key (@args){
					my $actual_hash = $self->format;
					$tmp_hash->{$key} = $actual_hash->{$key};
				}
				$state->format($tmp_hash);
				$output = "format @args ok";
			}
		}
		return $output;
	}
}

sub handle_header_line {
	my $self = shift;
	my $line = shift;
	my $state = shift;
	my $trigger = $self->header_trigger;
	my $match_pattern = '^##FORMAT=\<ID=(\w+),.+,Description=\"(.+)\"\>';
	$logger->debug("handing header line $line with match pattern $match_pattern");

	$line =~ /$match_pattern/;

	my $id = $1;
	my $desc  = $2;
	$logger->debug("got ID $id and Description \"$desc\"");
	if(length($id)>0 && length($desc)>0){
		$logger->debug("value of id $id and desc $desc"); 
	}else{
		$logger->fatal("Programmer error - FORMAT match pattern not working for line $line") if not ((defined($id) and defined($desc)));
		die "Programmer error - FORMAT match pattern not working for line $line";
	}

	$self->format->{$id} = $desc;
	$state->format->{$id} = $desc;
	# print STDERR Dumper($state->format);
}

sub header_trigger {
	my $self = shift;
	return "^##FORMAT";
}

return 1;
