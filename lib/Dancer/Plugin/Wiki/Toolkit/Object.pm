package Dancer::Plugin::Wiki::Toolkit::Object;

use warnings;
use strict;

use Wiki::Toolkit;
use base qw(Wiki::Toolkit);

# defaults
use constant FRONT_PAGE => 'FrontPage';

=head1 NAME

Dancer::Plugin::Wiki::Toolkit::Object;

=head1 DESCRIPTION

Subclassed Wiki::Toolkit::Object with added convenience methods.

=cut

=head1 METHODS

=head2 list_pages

List available pages.

=cut

sub list_pages {
	my ($wiki_object, $metadata) = @_;
	my (@pages);

	if ($metadata) {
		@pages = $wiki_object->list_nodes_by_metadata(%$metadata);
	}
	else {
		@pages = $wiki_object->list_all_nodes();
	}
	
	return @pages;
}

=head2 display_page

Displays page with the name PAGE.

=cut

sub display_page {
	my ($wiki_object, $page, $version, $format) = @_;
	my (%node);

	$page ||= FRONT_PAGE;
		
	if ($wiki_object->node_exists($page)) {
		if ($version) {
			%node = $wiki_object->retrieve_node({name => $page, version => $version});
		} else {
			%node = $wiki_object->retrieve_node($page);
		}
	}
	else {
		# dummy node
		%node = (content => '', checksum => undef, metadata => {});
	}
	
	unless (defined $format && $format eq 'raw') {
		my $ret;

		$ret = $wiki_object->format($node{content}, $node{metadata});

		return $ret;
	}

	# just return whole node
	return %node;
}

=head2 modify_page

Creates or modifies page.

=cut

sub modify_page {
	my ($wiki_object, $page, $content, $checksum, $metadata) = @_;
	my ($ret);

	$page ||= FRONT_PAGE;

	if (defined $checksum && $checksum !~ /\S/) {
		$checksum = undef;
	}
	
	$ret = $wiki_object->write_node($page, $content, $checksum, $metadata);

	unless ($ret) {
		die "Conflict editing node $page.";
	}

	return 1;
}

1;
