=head1 NAME                    

vcfshell::delegate::loc
  
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

package vcfshell::delegate::loc;
use strict;
use Log::Log4perl qw(get_logger);
my $logger = get_logger("vcfshell::delegate::loc");

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
	if($command eq 'loc'){
		# need actual position arguments passed into a loc command
		if(@args){
			# Looking to emulate a command for examining a SINGLE location, like: 
			# bcftools query -r chr1:182686 -f '%CHROM\t%POS\t%REF\t%ALT[\t%GT]\n' -s 2994STDY5774498,2994STDY5803390 data/combined_bcn_stjudes_genomes_exomes_h38.vep.severe.vcf.gz 
			# but present the in-shell view with samples on the y-axis and format/info/csq on the x-axis.
			my $loc = $args[0];

			# file argument
			my $file = $state->vcf_file;

			# sample argument (-s)
			my @samples = @{$state->samples};
			my $sample_string = join(',',@samples);

			# locus-specific non-info fields (ID REF ALT QUAL FILTER )
			my @non_info_loc_fields = ("REF","ALT","QUAL","FILTER");
			my $non_info_loc_fields_string = "%REF\t%ALT\t%QUAL\t%FILTER";
			
			# locus-specific info fields (e.g. %INFO/DP %INFO/INDEL %INFO/DP %INFO/DP4 )
			my @info_loc_fields = ("DP","INDEL","AC","DP4");
			my $info_loc_fields_string = "%INFO/DP\t%INFO/INDEL\t%INFO/AC\t%INFO/DP4";

			# format fields (e.g. [%GT %GQ %PL %DPR] )
			my @format_fields = ("GT","GQ","PL","DPR");
			my $format_fields_string = "%GT\t%GQ\t%PL\t%DPR\t";

			my $cmd = "bcftools query -f'$non_info_loc_fields_string\t$info_loc_fields_string\t[$format_fields_string]\n' -s$sample_string -r$loc $file";
			$logger->debug("fetching loc data with command $cmd");
			open(BCFT, "$cmd |") or die "Cant run $cmd - error: $!\n";

			my $output = "";
			my $locus_section = {};
			my $sample_section = {};

			my @locus_section_names = (@non_info_loc_fields,@info_loc_fields);
			my @all_fields = ();

			while(<BCFT>){
				chomp;
				@all_fields = split /\t/, $_;
				last;
			}
			my $pos = 0;
			# First pass through the locus-specific fields and place into the locus_section hash
			foreach my $field_name (@locus_section_names){
				my $field_value = $all_fields[$pos];
				$locus_section->{$field_name} = $field_value;
				$logger->debug("set locus field $field_name to value $field_value");
				$pos++;
			}
			foreach my $sample_name (@samples){
				foreach my $field_name (@format_fields){
					my $field_value = $all_fields[$pos];
					$sample_section->{$sample_name}->{$field_name} = $field_value;
					$logger->debug("sample $sample_name field $field_name to value $field_value");
					$pos++;
				}
			}

			# Now create and return the output block
			my $output = "";
			foreach my $field (@non_info_loc_fields){
				my $value = $locus_section->{$field};
				$output .= "$field\t$value\n"; 
			}
			foreach my $field (@info_loc_fields){
				my $value = $locus_section->{$field};
				$output .= "$field\t$value\n"; 
			}
			$output .= "SAMPLE\t\t";
			foreach my $format_field (@format_fields){
				$output .= "$format_field\t\t";
			}
			$output .= "\n";
			foreach my $sample (@samples){
				$output .= "$sample\t\t";
				foreach my $field (@format_fields){
					my $value = $sample_section->{$sample}->{$field};
					$output .= "$value\t\t"; 
				}
				$output .= "\n";
			}
			return $output;
		}
	}
}

sub handle_header_line {
	my $self = shift;
	my $line = shift;
	my $state = shift;
}

sub header_trigger {
	my $self = shift;
	return "^##INFO";
}

return 1;
