#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::More;
use DBI;

use lib qw(/home/janosch/perl/);
use DoIt::TableHandler;
use DoIt::UserTableHandler;


my $users = [
	{
		first_name => "firstname",
		last_name => "lastname",
		birth_date => "2018-01-01",
		mail_addr => 'first@second.com',
		phone_num => '+49 177 145 3486'
	},
	{
		first_name => "firstname2",
		last_name => "lastname2",
		birth_date => "2018-01-02",
		mail_addr => 'first@second.de',
		phone_num => '+49 177 145 3488'
	}
];

my $user1_updated = {
	first_name => "firstname_updated",
	last_name => "lastname_updated",
	birth_date => "2018-01-01",
	mail_addr => 'first@second.com',
	phone_num => '+49 177 145 3486'
};


my $dbh = createDataBaseHandle();
testCreateAbstract($dbh);
testConvertUpdateRecordToSqlStmt($dbh);
testConvertInsertRecordToSqlStmt($dbh);
testUserHandle($dbh);

done_testing();


sub createDataBaseHandle
{
	my $dbh = DBI->connect("dbi:mysql:doit_test", "doit_test", "doit_test",
		{ AutoCommit => 1, RaiseError => 1 });
	return $dbh;
}

sub testCreateAbstract
{
	my $dbh = shift;

	eval {
		my $table_handler = DoIt::TableHandler->new({
				dbh => $dbh
			});
		fail("TableHandler is abstract; cannot create object");
	};
	if ($@) {
		pass("TableHandler is abstract; cannot create object");
	}
}

sub testConvertUpdateRecordToSqlStmt
{
	my $dbh = shift;
	my $task_th = DoIt::TableHandler->createForDataSource({
			datasource => "TaskDataSource",
			dbh => $dbh
		});

	my $update_record = {
		id => 99,
		x => "x val",
		y => "y val"
	};
	my $sql_stmt = $task_th->convertUpdateRecordToSqlStmt($update_record);
	ok($sql_stmt eq "UPDATE task SET x = 'x val', y = 'y val' WHERE id = 99"
		|| $sql_stmt eq "UPDATE task SET y = 'y val', x = 'x val' WHERE id = 99",
		"update-record (2 values) converted to sql-statement");

	delete($update_record->{y});
	$sql_stmt = $task_th->convertUpdateRecordToSqlStmt($update_record);
	ok($sql_stmt eq "UPDATE task SET x = 'x val' WHERE id = 99",
		"update-record (1 value) converted to sql-statement");
}

sub testConvertInsertRecordToSqlStmt
{
	my $dbh = shift;
	my $task_th = DoIt::TableHandler->createForDataSource({
			datasource => "TaskDataSource",
			dbh => $dbh
		});

	my $insert_record = {
		x => "x val",
		y => "y val"
	};
	my $sql_stmt = $task_th->convertInsertRecordToSqlStmt($insert_record);
	ok($sql_stmt eq "INSERT INTO task (x, y) VALUES ('x val', 'y val')",
		"insert-record (2 values) converted to sql-statement");

	delete($insert_record->{y});
	$sql_stmt = $task_th->convertInsertRecordToSqlStmt($insert_record);
	ok($sql_stmt eq "INSERT INTO task (x) VALUES ('x val')",
		"insert-record (1 values) converted to sql-statement");
}

sub testUserHandle
{
	my $dbh = shift;

	my $user_th = DoIt::TableHandler->createForDataSource({
			datasource => "UserDataSource",
			dbh => $dbh
		});

	is($user_th->getTable(), "user", "UserTableHandler's table is 'user'");

	$user_th->clearTable();
	my $id1 = $user_th->insertRecord({ record => $users->[0] });
	$users->[0]->{id} = $id1;
	my $inserted_user = $user_th->fetchRecordWithIdAsHashref({ id => $id1 });
	testEqualHashes($users->[0], $inserted_user);
	is($user_th->getTotalRows(), 1, "1 user inserted");

	my $id2 = $user_th->insertRecord({ record => $users->[1] });
	$users->[1]->{id} = $id2;
	is($user_th->getTotalRows(), 2, "2 users inserted");

	testFetchRecordsInRange($user_th, 0, 1);
	testFetchRecordsInRange($user_th, 1, 2);
	testFetchRecordsInRange($user_th, 0, 2);

	$user1_updated->{id} = $id1;
	$user_th->updateRecord({ record => $user1_updated});
	my $updated_user = $user_th->fetchRecordWithIdAsHashref({ id => $id1 });
	testEqualHashes($user1_updated, $updated_user);

	$user_th->removeRecordWithId({ id => $id1 });
	my $user =  $user_th->fetchRecordWithIdAsHashref({ id => $id1 });
	is(scalar(keys(%$user)), 0, "user removed");
	is($user_th->getTotalRows(), 1, "1 user left");

	$user_th->clearTable();
	is($user_th->getTotalRows(), 0, "user-table cleared");
}

sub testEqualHashes
{
	my $hashref1 = shift;
	my $hashref2 = shift;

	is(scalar(keys(%$hashref1)), scalar(keys(%$hashref2)),
		"hashref1 and hashref2 have the same number of keys");
	foreach my $key (keys(%$hashref1)) {
		is($hashref1->{$key}, $hashref2->{$key}, "same value for key '$key'");
	}
}

sub testFetchRecordsInRange
{
	my ($user_th, $start_row, $end_row_excl) = @_;

	my $records = $user_th->fetchRecordsInRange({
			start_row => $start_row,
			end_row_excl => $end_row_excl
		});

	for (my $i = $start_row; $i < $end_row_excl; ++$i) {
		testEqualHashes($users->[$i], $records->[$i - $start_row]);
	}
}
