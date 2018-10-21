package DoIt::TableHandler;

use strict;
use warnings;
use lib qw(/home/janosch/perl/);
use MyUtils::ArgumentValidation qw(assertArgsExist);
use DoIt::TaskCommentTableHandler;
use DoIt::TaskTableHandler;
use DoIt::UserTableHandler;


sub createForDataSource
{
	my $class = shift;
	my $args = shift;
	assertArgsExist($args, ["datasource", "dbh"]);
	my $datasource = $args->{datasource};
	my $dbh = $args->{dbh};

	my $table_handler;
	if ($datasource eq "TaskCommentDataSource") {
		$table_handler = DoIt::TaskCommentTableHandler->new({ dbh => $dbh });
	}
	elsif ($datasource eq "TaskDataSource") {
		$table_handler = DoIt::TaskTableHandler->new({ dbh => $dbh });
	}
	elsif ($datasource eq "UserDataSource") {
		$table_handler = DoIt::UserTableHandler->new({ dbh => $dbh });
	}
	else {
		die("unknown datasource\n");
	}
	return $table_handler;
}

# This is an abstract class.
# new can only be called for a derived class.
sub new
{
	my $class = shift;
	my $args = shift;
	assertArgsExist($args, ["dbh"]);

	return bless({ dbh => $args->{dbh}, table => $class->getTable() }, $class);
}

sub getTable
{
	die("getTable must be implemented by derived class");
}

sub getDbh
{
	my $self = shift;

	return $self->{dbh};
}

sub insertRecord
{
	my $self = shift;
	my $args = shift;
	assertArgsExist($args, ["record"]);
	my $record = $args->{record};
	# todo Maybe check, that record isn't empty.
	
	my ($sql_stmt, $sql_values) = $self->convertInsertRecordToSql($record);

	my $sth = $self->getDbh->prepare($sql_stmt);
	$sth->execute(@$sql_values);

	# Return id of updated record.
	return $sth->{mysql_insertid};
}

sub convertInsertRecordToSql
{
	my $self = shift;
	my $record = shift;

	my $keys = [];
	my $values = [];
	foreach my $record_key (keys(%$record)) {
		push(@$keys, $record_key);
		push(@$values, $record->{$record_key});
	}

	my $sql_stmt = "INSERT INTO " . $self->getTable() . " (";	# INSERT INTO user (...
	foreach my $col_name (@$keys) {
		$sql_stmt .= $col_name . ", ";
	}
	$sql_stmt =~ s/,\s*$//;
	$sql_stmt .= ") VALUES (";	# ...first_name, last_name) VALUES (...
	foreach my $col_name (@$keys) {
		$sql_stmt .= "?, ";
	}
	$sql_stmt =~ s/,\s*$//;
	$sql_stmt .= ")";			# ...?, ?)

	return ($sql_stmt, $values);
}

# Return the number of rows in our table.
sub getTotalRows
{
	my $self = shift;
	my $args = shift;
	assertArgsExist($args, ["criteria"]);

	my ($where_condition, $values) = createWhereConditionFromCriteria($args->{criteria});

	my $sth = $self->getDbh->prepare(
		"SELECT COUNT(*) FROM " . $self->getTable() . $where_condition);
	$sth->execute(@$values);
	my $total_rows = $sth->fetchrow_arrayref();
	return $total_rows->[0]; # there is just one column
}

# Fetch and return all records from start_row up to (but not
# including) end_row_excl.
sub fetchRecordsInRange
{
	my $self = shift;
	my $args = shift;
	assertArgsExist($args, ["start_row", "end_row_excl", "criteria"]);

	my ($where_condition, $values) = createWhereConditionFromCriteria($args->{criteria});

	my $sth = $self->getDbh->prepare(
		"SELECT * FROM " . $self->getTable() . $where_condition . " LIMIT ?, ?");
	$sth->execute(@$values,
		$args->{start_row},								# offset/start_row
		$args->{end_row_excl} - $args->{start_row});	# row_count

	my $records = [];
	while (my $row_hashref = $sth->fetchrow_hashref()) {
		push(@$records, $row_hashref);
	}
	return $records;
}

sub createWhereConditionFromCriteria
{
	my $criteria = shift;
	my $where_condition = "";

	my $keys = [];
	my $values = [];
	foreach my $key (keys(%$criteria)) {
		push(@$keys, $key);
		push(@$values, $criteria->{$key});
	}

	if (scalar(@$keys) > 0) {
		$where_condition = " WHERE $keys->[0] = ?";
		for (my $i = 1; $i < scalar(@$keys); ++$i) {
			$where_condition .= " AND $keys->[$i] = ?";
		}
	}

	return ($where_condition, $values);
}

sub removeRecordWithId
{
	my $self = shift;
	my $args = shift;
	assertArgsExist($args, ["id"]);

	$self->getDbh->do("DELETE FROM ". $self->getTable() .
		" WHERE id = ?", undef, $args->{id});
}

sub updateRecord
{
	my $self = shift;
	my $args = shift;
	assertArgsExist($args, ["record"]);
	my $record = $args->{record};
	
	my $id = $record->{id};
	my ($sql_stmt, $values) = $self->convertUpdateRecordToSqlStmt($record);

	$self->getDbh->do($sql_stmt, undef, @$values);

	# Return id of updated record.
	return $id;
}

sub convertUpdateRecordToSqlStmt
{
	my $self = shift;
	my $record = shift;

	# Get id.
	if (!exists($record->{id})) {
		die("id is missing in update-record");
	}

	# Create sql-statement.
	my $sql_stmt = "UPDATE " . $self->getTable() . " SET ";
	my $values = [];
	foreach my $field_key (keys(%$record)) {
		if ($field_key ne "id") {
			$sql_stmt .= $field_key . " = ?, ";
			push(@$values, $record->{$field_key});
		}
	}
	# Remove last comma.
	$sql_stmt =~ s/,\s*$//;
	$sql_stmt .= " WHERE id = ?";
	push(@$values, $record->{id});

	return ($sql_stmt, $values);
}

sub fetchRecordWithIdAsHashref
{
	my $self = shift;
	my $args = shift;

	# Get id from arguments.
	assertArgsExist($args, ["id"]);
	my $id = $args->{id};

	# Fetch record with given id.
	my $sth = $self->getDbh->prepare(
		"SELECT * FROM " . $self->getTable() . " WHERE id = ?");
	$sth->execute($id);
	my $record = $sth->fetchrow_hashref();
	$sth->finish();
	return $record;
}

sub clearTable
{
	my $self = shift;
	my $sth = $self->getDbh->do("DELETE FROM " . $self->getTable);
}

1;
