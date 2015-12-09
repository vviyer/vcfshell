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

sub new
{
    my $class = shift;
    my $self = {
        _config => shift,
    };
    # Print all the values just for clarification.
    bless $self, $class;
    $self->{_info} = {};
    return $self;
}

sub config {
	my ($self) = shift;
	return $self->{_config};
}

sub handle_command {
	my ($self, $state, $command, @args) = @_;
	if($command eq 'info'){
		# If you have no extra sample args, then just return a string of all info fields and descriptions 
		my $output = "";
		if(!scalar(@args)){
			my $output_format = "%-15s%-15s\n";
			foreach my $key (keys %{$state->info}){
				my $desc = $state->info->{$key};
				$logger->debug("INFO command $key $desc");
				$output .= sprintf($output_format,$key,$desc);
			}
		}else{
			# Here we've been given a list of keys, so we have to make a new hash with the key-subset 
			my $tmp_hash = {};
			foreach my $key (@args){
				my $actual_hash = $self->info;
				$tmp_hash->{$key} = $actual_hash->{$key};
			}
			$state->info($tmp_hash);
			$output = "info @args ok";
		}
		return $output;
	}
}

sub handle_header_line {
	my $self = shift;
	my $line = shift;
	my $state = shift;
	my $trigger = $self->header_trigger;
	my $match_pattern = '^##INFO=\<ID=(\w+),.+,Description=\"(.+)\"\>';
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

	$self->info->{$id} = $desc;
	$state->info->{$id} = $desc;
}

sub header_trigger {
	my $self = shift;
	return "^##INFO";
}

sub info {
	my $self = shift;
	my $arg = shift;
	if($arg){
		$self->{_info} = $arg;
	}
	return $self->{_info};
}

return 1;
