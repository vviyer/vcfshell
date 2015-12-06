use strict;
use Term::ReadLine;
use Term::ReadLine::Gnu;
use Config::Simple;
use Module::Load;
use Log::Log4perl qw (:easy);
Log::Log4perl->easy_init($DEBUG);
use Data::Dumper;

# use Getopt::Long;

# Initialise config files
# Note: there are very few actual command line args 
# - the idea being to mostly drive off the config file
my $config;
my $state;
my $triggers = {};

#GetOptions(
#	        "user_config=s"=>\$user_config_file, 
#	        "log_file=s"=>\$log_file        
#);  

# Write basic and user configs into the $config hash
initialise_basic_config($ENV{HOME}."/.vcfshell.basic.conf");
initialise_user_config($ENV{HOME}."/.vcfshell.user.conf");

# Scoop up the delegates defined in the basic & user configs and prime trigger & state 
initialise_delegates();
DEBUG Data::Dumper::Dump([$triggers]);

my $output = "";

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

sub add_delegate_trigger {
	my $triggers = shift;
	my $delegate = shift;
	$triggers->{$delegate->trigger} = $delegate;
}

sub initialise_delegates{
	foreach my $delegate (@{$config->param("delegate.delegates")}){
		DEBUG "$delegate\n\n";
		my $delegate_class = "vcfshell::delegate::${delegate}";
		DEBUG " trying to load $delegate_class\n";
		load($delegate_class);
		my $obj = $delegate_class->new();
		add_delegate_trigger($triggers, $obj);
		DEBUG "GOT $obj with trigger ".$obj->trigger."\n";
	}
}

#sub completion {
#    my ($text, $state, $start, $end) = @_;
#    if ($text eq "yay") {
#        return "yayayaya";;
#    }
#
#    else {
#        # return Term::ReadLine::Gnu->filename_completion_function($text, $state);
#    }
#}

my $term = new Term::ReadLine 'vcfshell';

#Set up the completion function
my $attribs = $term->Attribs;
sub completion {
        my ($text, $line, $start, $end) = @_;
        # If first word then username completion, else filename completion
        if (substr($line, 0, $start) =~ /^\s*$/) {
            return $term->completion_matches($text, $attribs->{'username_completion_function'});
        } else {
            return ();
        }
    }
$attribs->{attempted_completion_function} = \&completion;;

my $OUT = $term->OUT || \*STDOUT;
my $prompt = ">> ";
while ( defined ($_ = $term->readline($prompt)) ) {
	print $OUT "hi\n";
	$term->addhistory($_) if /\S/;
}

return 1;
