#
# Use Term::Readline to present an interactive shell for ad-hoc vcf interrogation
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
my $session_state = vcfshell::state->new();
my $delegates = {};
my $triggers = {};
my $user_config_file = "";
my $vcf_file = "";

my $logger = get_logger();

GetOptions(
	"vcf_file=s"=>\$vcf_file, 
	"user_config=s"=>\$user_config_file, 
);  

# Write basic and user configs into the $config hash
initialise_basic_config($ENV{HOME}."/.vcfshell.basic.conf");
initialise_user_config($ENV{HOME}."/.vcfshell.user.conf");

# Scoop up the delegates defined in the basic & user configs and prime trigger & state 
initialise_delegates();

$session_state->vcf_file($vcf_file);
parse_header($vcf_file);

my $output = "";

sub add_delegate_trigger {
	my $triggers = shift;
	my $delegate = shift;
	$triggers->{$delegate->header_trigger} = $delegate;
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
	foreach my $delegate_name (keys %$delegates){
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

my $term = new Term::ReadLine 'vcfshell';

#Set up the completion function
my $attribs = $term->Attribs;

$attribs->{attempted_completion_function} = \&completion;;

my $OUT = $term->OUT || \*STDOUT;
my $prompt = "vcfs> ";

my $output = "";
while ( defined ($_ = $term->readline($prompt)) ) {
	# The autocompletion has already happened when we get to this point 
	foreach my $delegate_name (keys %$delegates){
		my $delegate = $delegates->{$delegate_name};
		$logger->debug("handle command with full line $_");
		my ($command, @args) = split /\s+/,$_;
		$logger->debug("handle command with $session_state, $command, @args");
		$output = $delegate->handle_command($session_state, $command, @args);
		if(length($output)>0){
			$logger->debug("found output $output from $delegate_name\n");
			last;
		}
	}

	print $OUT "$output\n";

	# only add to history after all processing complete
	$term->addhistory($_) if /\S/;
}

return 1;
