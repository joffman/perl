package MyUtils::ArgumentValidation;

use strict;
use warnings;
use lib qw(/home/janosch/perl/);

use Exporter qw(import);
our @EXPORT_OK = qw(assertArgsExist);


## Die if required arguments are not part of the given arguments.
##
## args: Given arguments as hashref.
## required_args: Names of required arguments (argument-keys) as arrayref.
##
## Return: Nothing if required arguments are part of the given arguments.
##	Die otherwise.
sub assertArgsExist
{
	my $args = shift;
	my $required_arguments = shift;

	foreach my $required_arg (@$required_arguments) {
		if (!exists($args->{$required_arg})) {
			die("argument '$required_arg' is missing");
		}
	}
}
