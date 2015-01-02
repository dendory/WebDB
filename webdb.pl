#!/usr/bin/perl
#
# webdb.pl - Simple web configuration load/save script by Patrick Lambert - http://dendory.net
#
use strict;
use CGI;
use DBI;
use MIME::Base64 qw(encode_base64 decode_base64);
my $cgi = new CGI;
my ($db, $sql, $secret);
my @chars = ("A".."Z", "a".."z", "0".."9");
my %errcodes = (200, "OK", 400, "Bad Request", 401, "Unauthorized", 404, "Not Found", 405, "Method Not Allowed", 409, "Conflict", 412, "Invalid Length", 500, "Internal Server Error");

#
# SQLite database path:
#
my $dbname = "webdb.sqlite";

# Main loop
if($cgi->param("register")) # register
{
	my $appname = encode_base64($cgi->param("register"), "");
	if(length($appname) < 5 || length($appname) > 99)
	{
		output(412, "Length of app name must be between 5 and 100 characters.");
	}
	else
	{
		$db = DBI->connect("dbi:SQLite:dbname=" . $dbname) or do
		{
			output(500, "Can't connect to database. " . $DBI::errstr);
		};
		$sql = $db->prepare("SELECT * FROM apps WHERE name=?");
		$sql->execute($appname);
		while (my @res = $sql->fetchrow_array())
		{
			output(409, "App name already exists.");
			exit(0);
		}
		$secret .= $chars[rand @chars] for 1..64;
		$sql = $db->prepare("INSERT INTO apps VALUES (?, ?, ?)");
		my $ip = $cgi->remote_addr();
		$sql->execute($appname, $secret, $ip);
		$sql = $db->prepare("CREATE TABLE " . $secret . " (key text, value text, time int)");
		$sql->execute();
		$db->disconnect;
		output(200, $secret);
	}
}
elsif($cgi->param("save") && $cgi->param("secret") && $cgi->param("data")) # save
{
	my $appname;
	my $key = encode_base64($cgi->param("save"), "");
	my $data = encode_base64($cgi->param("data"), "");
	$secret = $cgi->param("secret");
	if(length($secret) != 64)
	{
		output(412, "Length of secret must be 64 characters.");
	}
	elsif(length($data) > 9999)
	{
		output(412, "Length of data must be below 10,000 characters.");
	}
	elsif(length($key) < 5 || length($key) > 99)
	{
		output(412, "Length of key must be between 5 and 100 characters.");
	}
	elsif ($secret =~ m/[^a-zA-Z0-9]/)
	{
		output(400, "Invalid secret value.");
	}
	else
	{
		$db = DBI->connect("dbi:SQLite:dbname=" . $dbname) or do
		{
			output(500, "Can't connect to database. " . $DBI::errstr);
		};
		$sql = $db->prepare("SELECT * FROM apps WHERE secret=?");
		$sql->execute($secret);
		while (my @res = $sql->fetchrow_array())
		{
			$appname = $res[1];
		}
		if(!$appname)
		{
			output(401, "Invalid secret value.");
			exit(0);
		}
		$sql = $db->prepare("DELETE FROM " . $secret . " WHERE key=?");
		$sql->execute($key);
		$sql = $db->prepare("INSERT INTO " . $secret . " VALUES (?, ?, ?)");
		$sql->execute($key, $data, time());
		output(200, "Saved.");
	}
}
elsif(($cgi->param("load") || $cgi->param("timestamp")) && $cgi->param("secret")) # load & timestamp
{
	my $appname;
	my $key;
	if($cgi->param("load")) { $key= encode_base64($cgi->param("load"), ""); }
	else { $key= encode_base64($cgi->param("timestamp"), ""); }
	$secret = $cgi->param("secret");
	if(length($secret) != 64)
	{
		output(412, "Length of secret must be 64 characters.");
	}
	elsif(length($key) < 4 || length($key) > 99)
	{
		output(412, "Length of key must be between 4 and 100 characters.");
	}
	elsif ($secret =~ m/[^a-zA-Z0-9]/)
	{
		output(400, "Invalid secret value.");
	}
	else
	{
		$db = DBI->connect("dbi:SQLite:dbname=" . $dbname) or do
		{
			output(500, "Can't connect to database. " . $DBI::errstr);
		};
		$sql = $db->prepare("SELECT * FROM apps WHERE secret=?");
		$sql->execute($secret);
		while (my @res = $sql->fetchrow_array())
		{
			$appname = $res[1];
		}
		if(!$appname)
		{
			output(401, "Invalid secret value.");
			exit(0);
		}
		$sql = $db->prepare("SELECT * FROM " . $secret . " WHERE key=?");
		$sql->execute($key);
		while (my @res = $sql->fetchrow_array())
		{
			if($cgi->param("load")) { output(200, decode_base64($res[1])); }
			else { output(200, $res[2]); }
			exit(0);
		}
		output(404, "The key requested was not found.");
	}
}
else # unknown request
{
	output(405, "GET or POST parameters should be one of the following: register = <app name>, save = <key> & data = <text> & secret = <secret>, load = <key> & secret = <secret>, timestamp = <key> & secret = <secret>");
}

# Output code
sub output
{
	my ($status, $msg) = @_;
	print $cgi->header("text/plain", $status . " " . $errcodes{$status});
	print $msg;
}
