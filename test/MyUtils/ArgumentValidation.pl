#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::More;
use lib qw(/home/janosch/perl/);
use MyUtils::ArgumentValidation qw(assertArgsExist);

my $args = {
	arg_empty => '',
	arg_undef => undef,
	arg_int => 5,
	arg_float => 5.5,
	arg_string => 'hi',
	arg_hashref => { a => 5 },
	arg_arrayref => [5, 3]
};
my $existent_args = [
	"arg_empty",
	"arg_undef",
	"arg_int",
	"arg_float",
	"arg_string",
	"arg_hashref",
	"arg_arrayref"
];
my $non_existent_args = ["bla", "", "blub"];

sub testExistentArgs
{
	foreach my $req_arg (@$existent_args) {
		eval {
			assertArgsExist($args, [$req_arg]);
			pass("argument '$req_arg' exists");
		};
		if ($@) {
			fail("argument '$req_arg' exists");
		}
	}
}

sub testNonExistentArgs
{
	foreach my $no_arg (@$non_existent_args) {
		eval {
			assertArgsExist($args, [$no_arg]);
			fail("argument '$no_arg' does not exists");
		};
		if ($@) {
			pass("argument '$no_arg' does not exists");
		}
	}
}

sub testAllExistentArgs
{
	eval {
		assertArgsExist($args, $existent_args);
		pass("all existent argument exist");
	};
	if ($@) {
		fail("all existent argument exist");
	}
}

sub testMixedArgs
{
	my $mixed_args = [@$existent_args];
	push(@$mixed_args, "non-existent-argument");

	eval {
		assertArgsExist($args, $mixed_args);
		fail("not all arguments in mixed_args exist");
	};
	if ($@) {
		pass("not all arguments in mixed_args exist");
	}
}


testExistentArgs();
testNonExistentArgs();
testAllExistentArgs();
testMixedArgs();

done_testing();
