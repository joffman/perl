package DoIt::UserTableHandler;

use strict;
use warnings;
use lib qw(/home/janosch/perl/);
use MyUtils::ArgumentValidation qw(assertArgsExist);

use DoIt::TableHandler;
our @ISA = ("DoIt::TableHandler");


sub getTable {
	return "user";
}

1;
