#
# Use Term::Readline to present an interactive shell for ad-hoc vcf interrogation
#
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
my $config;
my $state;
my $delegates = {};
my $triggers = {};
my $user_config_file = "";
my $vcf_file = "";
my $header_info = "";

GetOptions(
	        "vcf_file=s"=>\$vcf_file, 
	        "user_config=s"=>\$user_config_file, 
);  

# Write basic and user configs into the $config hash
initialise_basic_config($ENV{HOME}."/.vcfshell.basic.conf");
initialise_user_config($ENV{HOME}."/.vcfshell.user.conf");

# Scoop up the delegates defined in the basic & user configs and prime trigger & state 
initialise_delegates();
DEBUG sort(join(",",keys(%{$triggers})));

parse_header($vcf_file);

my $output = "";

sub add_delegate_trigger {
	my $triggers = shift;
	my $delegate = shift;
	$triggers->{$delegate->trigger} = $delegate;
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
		DEBUG "$delegate\n\n";
		my $delegate_class = "vcfshell::delegate::${delegate}";
		DEBUG " trying to load $delegate_class\n";
		load($delegate_class);
		my $obj = $delegate_class->new();
		$delegates->{$delegate_class} = $obj;
		add_delegate_trigger($triggers, $obj);
		DEBUG "GOT $obj with trigger ".$obj->trigger."\n";
	}
}

parse_header {
	my $file = shift;
	die "must provide vcf file input" unless $file;
	foreach my $delegate (values %$delegates){
		my $cmd = "bcftools query -h $file | egrep '$delegate_trigger' ";
		open(BCFT, "$cmd |") or die "Cant run $cmd\n";
		while(<BCFT>){
			chomp;
			$delegate->handle_line($_,$header_info);
		}
	}
	open(BCFT,"$cmd |") or die;
	while(<BCFT>){
		print "$_";
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

$attribs->{attempted_completion_function} = \&completion;;

my $OUT = $term->OUT || \*STDOUT;
my $prompt = ">> ";
while ( defined ($_ = $term->readline($prompt)) ) {
	print $OUT "hi\n";
	$term->addhistory($_) if /\S/;
}

return 1;
