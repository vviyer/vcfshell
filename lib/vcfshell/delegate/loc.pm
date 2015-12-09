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
			my $output = "";
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
			my $info_loc_fields_string = "%INFO/DP\t%INFO/INDEL\tINFO/AC\t%INFO/DP4";

			# format fields (e.g. [%GT %GQ %PL %DPR] )
			my @format_fields = ("GT","GQ","PL","DPR");
			my $format_fields_string = "[%GT\t%GQ\t%PL\t%DPR]";

			my $cmd = "bcftools query -f'$non_info_loc_fields_string\t$info_loc_fields_string\t[\t$format_fields_string]' -s$sample_string -r$loc $file";
			$logger->debug("fetching loc data with command $cmd");
			open(BCFT, "$cmd |") or die "Cant run $cmd - error: $!\n";
			my $output = "";
			my $locus_section = {};
			my $sample_section = {};
			while(<BCFT>){
				chomp;
				$output .= "$_\n";
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
