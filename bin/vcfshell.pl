use strict;
use Term::ReadLine;
use Config::Simple;
use Module::Load;
# use Getopt::Long;

# Initialise config files
# Note: there are very few actual command line args 
# - the idea being to mostly drive off the config file
my $config;
my $state;
my $triggers;

#GetOptions(
#	        "user_config=s"=>\$user_config_file, 
#	        "log_file=s"=>\$log_file        
#);  

# Write basic and user configs into the $config hash
initialise_basic_config($ENV{HOME}."/.vcfshell.basic.conf");
initialise_user_config($ENV{HOME}."/.vcfshell.user.conf");

# Scoop up the delegates defined in the basic & user configs and prime trigger & state 
initialise_delegates();

my $output = "";

my $term = new Term::ReadLine 'vcfshell';
my $OUT = $term->OUT || \*STDOUT;
my $prompt = ">> ";
while ( defined ($_ = $term->readline($prompt)) ) {
	print $OUT "hi\n";
	$term->addhistory($_) if /\S/;
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
		print STDERR "$delegate\n\n";
		my $delegate_class = "vcfshell::delegate::${delegate}";
		print STDERR " trying to load $delegate_class\n";
		load($delegate_class);
		my $obj = $delegate_class->new();
		print "GOT $obj with trigger ".$obj->trigger."\n";
	}
}
