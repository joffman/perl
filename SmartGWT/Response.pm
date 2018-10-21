package SmartGWT::Response;

use strict;
use warnings;
use JSON;
use lib qw(/home/janosch/perl);
use SmartGWT::StatusCodes;


sub new {
	my $class = shift;
	my $args = shift;
	$args = $args // {};

	return bless({
		status		=> $SmartGWT::StatusCodes::SUCCESS,
		startRow	=> 0,
		endRow		=> 0,
		totalRows	=> 0,
		data		=> [],
		%$args				# override defaults
	}, $class);
}

sub setStatus {
	my $self = shift;
	$self->{status} = shift;
}

sub setStartRow {
	my $self = shift;
	$self->{startRow} = shift;
}

sub setEndRow {
	my $self = shift;
	$self->{endRow} = shift;
}

sub setTotalRows {
	my $self = shift;
	$self->{totalRows} = shift;
}

sub setData {
	my $self = shift;
	my $data = shift;

	if (ref($data) ne "ARRAY") {
		die("data has to be an array-ref");
	}

	$self->{data} = $data;
}

sub addDataRecord {
	my $self = shift;
	my $data_record = shift;

	# Maybe check, if the record is empty.

	push(@{$self->{data}}, $data_record);
}

sub toJsonString {
	my $self = shift;

	my $response = {
		response => {%$self}	# unbless $self
	};
	return encode_json($response);
}

1;
