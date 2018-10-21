package SmartGWT::RequestParsing;

use strict;
use warnings;
use JSON;

use Exporter qw(import);
our @EXPORT = qw();
our @EXPORT_OK = qw(read_post_body);


sub read_post_body
{
	my $r = shift;
	
	# Read and parse post-data.
	my $post_data;
	$r->read($post_data, $r->headers_in()->{"Content-length"});
	$post_data = decode_json($post_data);

	return $post_data;
}

1;
