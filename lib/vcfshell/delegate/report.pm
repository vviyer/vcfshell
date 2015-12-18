=head1 NAME                    

vcfshell::delegate::report
  
=head1 DESCRIPTION
  
(typically) Batch reporting module 
- reads the supplied state, containing the formatting information
- reads the vcf file
- converts state to tab file! 
  
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

package vcfshell::delegate::report;
use strict;
use Data::Dumper;
use Log::Log4perl qw(get_logger);
my $logger = get_logger("vcfshell::delegate::report");

sub new
{
    my $class = shift;
    my $self = {
        _config => shift,
    };
    # Print all the values just for clarification.
    bless $self, $class;
    return $self;
}

sub config {
	my ($self) = shift;
	return $self->{_config};
}

sub handle_command {
	my ($self, $state, $command, @args) = @_;
	if($command eq 'report'){
		#
		# Must have state passed in to do this.
		if(!$state){
			return "must specify state to run report";
		}

		# if the report is run with arguments, establish a locus or set of loci using the arguments 
		my $loc;
		my $output_file;
		if(scalar(@args)){
			# args are filename location (both optional)
			# we have been passed both filename and location parameters
			$output_file = $args[0];		
			if(scalar(@args)>1){
				$loc = $args[1];
			}
		}

		$self->_run_report($state, $output_file, $loc);
		return "report done";
	}
}

sub _parse_bcftools_line {
	my $self = shift;
	my $line = shift;
	my $state = shift;


	my @samples = @{$state->samples};
	my @format_fields = keys(%{$state->format});

	# Put together the fields 
	my @non_info_loc_fields = ("REF","ALT","QUAL","FILTER");
	my @info_loc_fields = sort(keys($state->info)); 
	my @locus_section_names = (@non_info_loc_fields,@info_loc_fields);

	# Here is the actual line, split into bits
	my @all_fields = split /\t/, $line;
	$logger->debug("all fields @all_fields");

	my $pos = 0;
	my $locus_section = {};
	my $sample_section = {};
	# First pass through the locus-specific fields and place into the locus_section hash
	foreach my $field_name (@locus_section_names){
		my $field_value = $all_fields[$pos];
		$locus_section->{$field_name} = $field_value;
		$logger->debug("set locus field $field_name to value $field_value");
		$pos++;
	}
	my $longest_sample_name_length = 0;
	foreach my $sample_name (@samples){
		if($longest_sample_name_length < length($sample_name)){
			$longest_sample_name_length = length($sample_name);
		}
		foreach my $field_name (@format_fields){
			my $field_value = $all_fields[$pos];
			$logger->debug("sample section got $field_name with $field_value");
			$sample_section->{$sample_name}->{$field_name} = $field_value;
			$logger->debug("sample $sample_name field $field_name to value $field_value");
			$pos++;
		}
	}

	return ($locus_section,$sample_section);
}

sub _prepare_sample_string {
	my $self = shift;
	my $state = shift;

	# sample argument (-s)
	my @samples = @{$state->samples};
	my $sample_string = join(',',@samples);
	return $sample_string;
}

sub _prepare_non_info_loc_string {
	my $self = shift;
	my $state = shift;

	# locus-specific non-info fields (ID REF ALT QUAL FILTER )
	my @non_info_loc_fields = ("REF","ALT","QUAL","FILTER");
	my $non_info_loc_fields_string = "%REF\t%ALT\t%QUAL\t%FILTER";
	return $non_info_loc_fields_string;
}
			
sub _prepare_info_loc_string{
	my $self = shift;
	my $state = shift;

	# locus-specific info fields (e.g. %INFO/DP %INFO/INDEL %INFO/DP %INFO/DP4 )
	my @info_loc_fields = sort(keys($state->info)); # ("DP","INDEL","AC","DP4");
	my $info_loc_fields_string = ""; # "%INFO/DP\t%INFO/INDEL\t%INFO/AC\t%INFO/DP4";
	foreach my $info_field (@info_loc_fields){
		$info_loc_fields_string .= "%INFO/$info_field".'\t';
	}
	return $info_loc_fields_string;
}

sub _prepare_format_string {
	my $self = shift;
	my $state = shift;

	# format fields (e.g. [%GT %GQ %PL %DPR] )
	my @format_fields = sort(keys(%{$state->format}));# ("GT","GQ","PL","DPR");
	my $format_fields_string = "";# "%GT\t%GQ\t%PL\t%DPR\t";
	foreach my $format_field (@format_fields){
		$format_fields_string .= "%$format_field".'\t';
	}
	return $format_fields_string;
}

sub _print {
	my $self = shift;
	my $state = shift;
	my $locus_section = shift;
	my $sample_section = shift;
	my $output_fh = shift;

	my @format_fields = keys(%{$state->format});
	my @samples = @{$state->samples};

	# Put together the fields 
	my @non_info_loc_fields = ("REF","ALT","QUAL","FILTER");
	my @info_loc_fields = sort(keys($state->info)); 
	my @locus_section_names = (@non_info_loc_fields,@info_loc_fields);

	# Now create and return the output block
	my $output = "";
	my $loc = $locus_section->{CHR}.":".$locus_section->{POS};
	my $locus_format = "-15s%\t";
	$output .= sprintf($locus_format,$loc);
	foreach my $field (@non_info_loc_fields){
		my $value = $locus_section->{$field};
		$output .= sprintf($locus_format,$value);
	}
	foreach my $field (@info_loc_fields){
		my $value = $locus_section->{$field};
		$output .= sprintf($locus_format,$value);
	}

	#
	# Build up the sprintf format - one field for each "FORMAT" field printed
	my $sample_format = "";
	foreach my $field (@format_fields){
		$sample_format .= "%-15s";
	}

	# create a vector of actual sample values to fit into the format.
	foreach my $sample (@samples){
		my @all_format_values = ();
		foreach my $field (@format_fields){
			my $value = $sample_section->{$sample}->{$field};
			push @all_format_values, $value;
			$logger->debug("format value: pushed field $field with value $value");
		}
		$output .= sprintf($sample_format,@all_format_values);
	}
	$output .= "\n";

	print $output_fh $output;
}

=head2 NAME                    

_write_report

=head2 DESCRIPTION

Actually use the formatted strings to run bcftools query and then print - either to STDOUT or to the supplied input file

=cut
sub _run_report {
	my $self = shift;
	my ($state, $output_file, $loc) = @_;

	my $file = $state->vcf_file;
	my $sample_string = $self->_prepare_sample_string($state);
	my $non_info_loc_fields_string = $self->_prepare_non_info_loc_string($state);
	my $info_loc_fields_string = $self->_prepare_info_loc_string($state);
	my $format_fields_string = $self->_prepare_format_string($state);

	my $run_as_test;
	my $cmd;
	if(!$loc || ($loc eq 'test' || ($loc eq 'test_5'))){
		$run_as_test = 1;
		if($loc eq 'test_5'){
			$run_as_test = 5;
		}
		$loc = undef;
		$cmd = "bcftools query -f'$non_info_loc_fields_string\t${info_loc_fields_string}[$format_fields_string]\n' -s$sample_string $file\n";
	}else{
		$cmd = "bcftools query -f'$non_info_loc_fields_string\t${info_loc_fields_string}[$format_fields_string]\n' -s$sample_string -r$loc $file\n";
	}

	$logger->debug("fetching loc data with command $cmd");
	open(BCFT, "$cmd |") or die "Cant run $cmd - error: $!\n";


	# This is a repeat of the construction in the string-preps
	my @all_fields = ();

	my $output_fh;
	if($output_file){
		if($output_fh eq '-'){
			$output_fh = \*STDOUT;
		}else{
			open ($output_fh, ">$output_file") or die "cant open $output_file to write report";
		}
	}else{
		$output_fh = \*STDOUT;
	}

	my $iterates = 0;
	while(<BCFT>){
		chomp;
		my $locus_section = {};
		my $sample_section = {};
		my ($locus_section, $sample_section) = $self->_parse_bcftools_line($_, $state);
		$self->_print($state, $locus_section, $sample_section, $output_fh);
		if(($run_as_test)&&($iterates>$run_as_test)){
			last;
		}
		$iterates++;
	}
}

sub handle_header_line {
	my $self = shift;
	my $line = shift;
	my $state = shift;
}

sub header_trigger {
	my $self = shift;
}

return 1;
