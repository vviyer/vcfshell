=head1 NAME                    

vcfshell.pl
  
=head1 DESCRIPTION
  
Driver script for vcfshell interactive vcf snooper:
use Term::Readline to present an interactive shell for ad-hoc vcf interrogation
  
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
#
#
use strict;
use Term::ReadLine;
use Term::ReadLine::Gnu;
use Config::Simple;
use Module::Load;
use Log::Log4perl qw(get_logger :levels);
Log::Log4perl->init("conf/logger.conf");
use Data::Dumper;
use Getopt::Long;
use vcfshell::state;

# Initialise config files
my $config;
my $initial_state;
my $session_state;
my $delegates = {};
my @delegates_in_load_order = ();
my $triggers = {};
my $user_config_file;
my $vcf_file;
my $batch_command;
my $logger;

sub add_delegate_trigger {
	my $triggers = shift;
	my $delegate = shift;
	#If the delegate has exposed a trigger (some delegates may not)
	if($delegate->header_trigger){
		$triggers->{$delegate->header_trigger} = $delegate;
	}
}

sub completion {
    my ($text, $state, $start, $end) = @_;
    if ($text eq "yay") {
        return "yay autocompleted";;
    }
    else {
	    # TODO - work out why this works: This commented line 
	    # actually seems to correctly trigger filename completion
	    # return Term::ReadLine::Gnu->filename_completion_function($text, $state);
    }
}

sub initialise_basic_config{
	my $basic_config_file = shift;
	if(-e $basic_config_file){
		$config = new Config::Simple($basic_config_file)
	}else{
		die "TODO to write this section to make a new basic config file if one doesnt exist"
	}
}

sub initialise_user_config{
	my $user_config_file = shift;
	# die "TODO to write this section to make a new basic config file if one doesnt exist"
}

sub initialise_delegates{
	foreach my $delegate (@{$config->param("delegate.delegates")}){
		$logger->debug("$delegate\n\n");
		my $delegate_class = "vcfshell::delegate::${delegate}";
		push @delegates_in_load_order, $delegate_class; 
		$logger->debug(" trying to load $delegate_class\n");
		load($delegate_class);
		my $obj = $delegate_class->new();
		$obj->config($config);
		$delegates->{$delegate_class} = $obj;
		add_delegate_trigger($triggers, $obj);
		$logger->debug("GOT $obj with trigger ".$obj->header_trigger."\n");
	}
}

sub parse_header {
	my $file = shift;
	$logger->error("must provide vcf file input") unless $file;
	foreach my $delegate_name (@delegates_in_load_order){
		my $delegate = $delegates->{$delegate_name};
		my $delegate_trigger = $delegate->header_trigger;
		my $cmd = "bcftools view -h $file | egrep '$delegate_trigger' ";
		open(BCFT, "$cmd |") or die "Cant run $cmd - error: $!\n";
		while(<BCFT>){
			chomp;
			$delegate->handle_header_line($_, $session_state);
		}
	}
}

=head2 NAME                    
handle_input
=head2 DESCRIPTION
This is the main handler for the input, whether its coming from Term::ReadLine or is passed in via batch
=cut
sub handle_input {
	my $input = shift;
	my $output = "";
	foreach my $delegate_name (keys %$delegates){
		my $delegate = $delegates->{$delegate_name};
		$logger->debug("handle command with full line $_");
		my ($command, @args) = split /\s+/,$input;
		$logger->debug("handle command with $session_state, $command, @args");
		$output = $delegate->handle_command($session_state, $command, @args);
		if(length($output)>0){
			$logger->debug("found output $output from $delegate_name\n");
			last;
		}
	}
	return $output;
}

#
# Script processing starts here
#
GetOptions(
	"vcf_file=s"=>\$vcf_file, 
	"initial_state:s"=>\$initial_state, 
	"batch_command:s"=>\$batch_command, 
	"user_config=s"=>\$user_config_file, 
);  

if(!$vcf_file){
	die "have to provide vcf_file argument as --vcf_file\n";
}


# create an empty state instance - scope is this script
$session_state = vcfshell::state->new();
# initialise the root logger according to the conf/logger.conf file
$logger = get_logger();

# Write basic system configs into the $config hash 
# - This tells the system which delegates to load 
initialise_basic_config($ENV{HOME}."/.vcfshell.basic.conf");

# Scoop up the delegates defined in the config and prime the triggers & state 
initialise_delegates();

$session_state->vcf_file($vcf_file);
parse_header($vcf_file);

# If we are in batch, then initialise the state (if it's provided)
# and get the delegates to handle the input
# - print out any delegate-specific response
# - and stop! 
if($batch_command){
	# If we've been given an initial state, then use the state delegate to load the initial_state file 
	if($initial_state){
		my $state_delegate = $delegates->{'vcfshell::delegate::state'};
		die "cant find state delegate to load specified state" unless $state_delegate;
		$logger->debug("loading state $initial_state with delegate $state_delegate");
		$state_delegate->handle_command($session_state, "state", ("load",$initial_state));
		$logger->debug("loaded state $initial_state with delegate $state_delegate");
	}

	$session_state->batch_command($batch_command);
	my $output = handle_input($batch_command);
	print $output;
	exit(0);
}

# If we are not in batch (interactive!), 
# use Term::ReadLine to set up an interactive shell

my $term = new Term::ReadLine 'vcfshell';

#Set up the completion function
my $attribs = $term->Attribs;

$attribs->{attempted_completion_function} = \&completion;;

my $OUT = $term->OUT || \*STDOUT;
my $prompt = "vcfs> ";

while ( defined ($_ = $term->readline($prompt)) ) {

	my $output = "";

	# The autocompletion has already happened when we get to this point 

	$output = handle_input($_);
	print $OUT "$output\n";

	# only add to history after all processing complete
	$term->addhistory($_) if /\S/;
}

return 1;
