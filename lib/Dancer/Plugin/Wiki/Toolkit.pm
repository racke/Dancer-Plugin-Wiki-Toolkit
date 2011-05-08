package Dancer::Plugin::Wiki::Toolkit;

use warnings;
use strict;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::Database;

use Wiki::Toolkit;
use Dancer::Plugin::Wiki::Toolkit::Object;

=head1 NAME

Dancer::Plugin::Wiki::Toolkit - Wiki::Toolkit plugin for Dancer

=head1 VERSION

Version 0.0001

=cut

our $VERSION = '0.0001';


=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Wiki::Toolkit;

=head1 CONFIGURATION

=over 4

=item C<db_connection_name> (optional)

We use L<Dancer::Plugin::Database> to obtain database connections.  This option
allows you to specify the name of a connection defined in the config file to
use.  See the documentation for L<Dancer::Plugin::Database> for how multiple
database configurations work.  If this is not supplied or is empty, the default
database connection details in your configuration file will be used - this is
often what you want, so unless your application is dealing with multiple
databases, you probably won't need to worry about this option.

=back

=head2 DEFINING FORMATTERS

L<Wiki::Toolkit> can use more than one formatter at the same time.

Parameters can be passed to the formatters as follows:

  Wiki::Toolkit:
    formatters:
        UseMod:
            extended_links: 1
            allowed_tags: [pre]

=head1 SUBROUTINES/METHODS

=head2 wiki

=cut

my $wiki_tk_obj;

sub _setup_wiki_toolkit {
	my ($driver, $class, $settings, $store_object);

	# retrieve settings
	$settings = plugin_setting;

	# determine database driver
	$driver = database->{Driver}->{Name};

	# check whether Wiki::Toolkit supports this driver
	if ($driver eq 'mysql') {
		$class = 'Wiki::Toolkit::Store::MySQL';
	}
	elsif ($driver eq 'Pg') {
		$class = 'Wiki::Toolkit::Store::Pg';
	}
	elsif ($driver eq 'SQLite') {
		$class = 'Wiki::Toolkit::Store::SQLite';
	}
	else {
		Dancer::Logger::error("Database driver unsupported by Wiki::Toolkit: " . $driver);
		return;
	}
	
	# create an storage object
	eval "require $class";
	
 	if ($@) {
		die "Failed to load $class: $@\n";
	}
	eval {
		$store_object = $class->new(dbh => database)
	};
	if ($@) {
		die "Failed to instantiate $class: $@\n";
	}

	# now formatters
	my (@formatters, $fmt_object, $object, %parms);
	
	if (exists $settings->{formatters}) {
		if (ref($settings->{formatters}) eq 'HASH') {
			@formatters = keys(%{$settings->{formatters}});
		}
		else {
			@formatters = split(',', $settings->{formatters});
		}

		for (@formatters) {
			my $fmt;

			$fmt->{class} = "Wiki::Toolkit::Formatter::$_";
			$fmt->{options} = $settings->{formatters}->{$_} || {};
			
			$object = _load_formatter($fmt, $store_object);
			$parms{$_} = $object;
		}
		
		if (@formatters > 1) {
			require Wiki::Toolkit::Formatter::Multiple;

		    $fmt_object = Wiki::Toolkit::Formatter::Multiple->new(%parms);
		}
		else {
			$fmt_object = $object;
		}
	}

	# finally object
	$wiki_tk_obj = Wiki::Toolkit->new(store => $store_object,
									  formatter => $fmt_object);

	# register Wiki::Toolkit plugins
	# ...

	bless $wiki_tk_obj, 'Dancer::Plugin::Wiki::Toolkit::Object';
}


register wiki => sub {
	my ($arg, %opts) = @_;

	unless ($wiki_tk_obj) {
		# setup Wiki::Toolkit object
		_setup_wiki_toolkit();
	}

	$opts{function} ||= 'display';
	
	if ($opts{function} eq 'save') {
		return $wiki_tk_obj->modify_page($arg, $opts{content}, $opts{checksum});
	}
	
	# display page
	return $wiki_tk_obj->display_page($arg, $opts{version}, $opts{format});
};

register_plugin;

sub _load_formatter {
	my ($fmt, $store_object) = @_;
	my ($edit_prefix);

	eval "require $fmt->{class}";
	if ($@) {
		die "Failed to load $fmt->{class}: $@\n";
	}

	# we are passing an empty string to node_prefix to override the
	# default of the formatter in order to use <wiki>/MyPage URL for
	# MyPage

	eval {
		$edit_prefix = join('&amp;', '?action=edit', 'page=');
		$fmt->{object} = $fmt->{class}->new (store => $store_object,
											 node_prefix => '',
											 edit_prefix => $edit_prefix,
											 %{$fmt->{options}});
	};
	if ($@) {
		die "Failed to instantiate $fmt->{class}: $@\n";
	}

	return $fmt->{object};
}

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-wiki-toolkit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Wiki-Toolkit>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Wiki::Toolkit


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Wiki-Toolkit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Wiki-Toolkit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Wiki-Toolkit>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Wiki-Toolkit/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Dancer::Plugin::Wiki::Toolkit
