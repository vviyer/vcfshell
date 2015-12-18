=head1 NAME                    

vcfshell::delegate::state
  
=head1 DESCRIPTION
  
The session state contains information about display options:
This delegate handles commands to save / load or reset the session state 
  
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

package vcfshell::delegate::state;
use strict;
use Log::Log4perl qw(get_logger);
use Data::Dumper;
my $logger = get_logger("vcfshell::delegate::state");

my $DEFAULT_STATE_FILE = $ENV{HOME}."/.vcfshell.default.state";

sub new
{
    my $class = shift;
    my $self = {
        _config => shift,
    };
    # Print all the values just for clarification.
    $self->{_state_file} = $DEFAULT_STATE_FILE; 
    bless $self, $class;
    return $self;
};

sub config {
	my ($self) = shift;
	$self->{_state_file} = $DEFAULT_STATE_FILE;
	return $self->{_config};
}

=head2 NAME                    
handle_command

=head2 DESCRIPTION
If no args passed in, return the current location of the state file 

If the arg passed in is 'load' then 
- if there's no second argument, look for and load the state file ".vcfshell.default.state" (report if not found)
- if there IS a second argument, look for and load the state file in the second argument (report if not found) 

If the arg passed in is 'save' then require a second argument which is the location of the target file to save to.

If the only arg passed in is 'reset' then reset the state by re-reading the header
=cut
sub handle_command {
	my ($self, $state, $command, @args) = @_;
	if($command eq 'state'){
		$logger->debug("$command @args");
		my $output = "";
		# If there's no argument, report the location of the state file
		if(!scalar(@args)){
			if($self->state_file){
				if(-e $self->state_file){
					$output = "state file is: ".$self->state_file." (exists)";
				}else{
					$output = "state file should be: ".$self->state_file." (doesn't exists)";
				}
			}else{
				$output = "no state file set";
			}
		}else{
			# load or save state from default state file or supplied state file 
			if($args[0] eq 'load'){
				my $file_to_load = $DEFAULT_STATE_FILE;
				if(-e $file_to_load){
					if( scalar(@args) >  1 ){
						my $new_state_file = $args[1];
					}
					$logger->debug("loading file $file_to_load");
					my $returned_state = $self->_load_state($file_to_load);
					if($returned_state){
						my @tmp_keys = keys(%{ $returned_state }); 
						$logger->debug("loaded state file $file_to_load with keys @tmp_keys");
						$output = "loaded state file $file_to_load";
					}else{
						$output = "FAILED to load state from file $file_to_load";
					}
					# overwrite the contents of the hash at the pointer location without rewriting the hash itself
					foreach my $existing_key (keys %$state){
						$state->{$existing_key} = $returned_state->{$existing_key};
					}
					foreach my $new_key (keys %$returned_state){
						$state->{$new_key} = $returned_state->{$new_key};
					}
				}else{
					$output = "State file $file_to_load doesn't exist";
				}
			}elsif($args[0] eq 'save'){
				my $file_name = $self->state_file;
				if($args[1]){
					$file_name = $args[1];
				}else{
					$file_name = $DEFAULT_STATE_FILE;
				}
				$logger->debug("writing file $file_name");
				open(STATE,">$file_name") or die "cant open $file_name for writing";
				print STATE Data::Dumper->Dump([$state],['state']);
				close(STATE);
				$output = "saved state to file $file_name";
				# Take the state object, serialise and write to $file_name
			}
		}
		return $output;
	}
}

=head2 NAME                    
handle_header_line
=head2 DESCRIPTION
Does nothing
=cut
sub handle_header_line {
}

=head2 NAME                    
header_trigger
=head2 DESCRIPTION
Returns undef so trigger is ignored by driver: this delegate is deaf to the header
=cut
sub header_trigger {
	my $self = shift;
	return undef; 
}

=head2 NAME                    
_load_state
=head2 DESCRIPTION
Reads the state file (specified or default) from disk 
Returns new state hash.
=cut
sub _load_state {
	my $self = shift;
	my $file_to_load = shift;
	$logger->debug("trying to load state file ".$file_to_load);
	open(STATE,"<".$file_to_load) or die "cannot open $file_to_load";
	my $s = "";
	while(<STATE>){
		$s .= $_;
	}
	close(STATE);
	my $state;
	#
	$state = eval($s);
	return $state;
}

sub state_file {
	my $self = shift;
	my $arg = shift;
	if($arg){
		$self->{_state_file} = $arg;
	}
	return $self->{_state_file};
}
