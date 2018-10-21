package DoIt::TaskCommentTableHandler;

use strict;
use warnings;
use POSIX qw(strftime);
use lib qw(/home/janosch/perl/);
use MyUtils::ArgumentValidation qw(assertArgsExist);

use DoIt::TableHandler;
our @ISA = ("DoIt::TableHandler");


sub getTable {
	return "task_comment";
}

sub insertRecord
{
	my $self = shift;
	my $args = shift;
	assertArgsExist($args, ["record"]);
	my $record = $args->{record};

	$record->{created_datetime} = $record->{modified_datetime} = strftime("%F %T", localtime());
	return $self->SUPER::insertRecord({ record => $record });
}

sub updateRecord
{
	my $self = shift;
	my $args = shift;
	assertArgsExist($args, ["record"]);
	my $record = $args->{record};

	# Update modified_datetime.
	$record->{modified_datetime} = strftime("%F %T", localtime());

	return $self->SUPER::updateRecord({ record => $record });
}

1;
