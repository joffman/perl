#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use lib qw(/home/janosch/perl/);
use SmartGWT::Response;

my $response = SmartGWT::Response->new();
$response->addDataRecord({
		a => "This is a single line.",
		b => "These are
		two lines."
	});

print($response->toJsonString(), "\n");
