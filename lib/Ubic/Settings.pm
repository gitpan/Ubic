package Ubic::Settings;
BEGIN {
  $Ubic::Settings::VERSION = '1.32_02';
}

use strict;
use warnings;

# ABSTRACT: ubic settings


use Params::Validate qw(:all);

use Ubic::Settings::ConfigFile;

our $settings;

sub _file_settings {
    my $file_settings = {};
    if ($ENV{HOME} and -e "$ENV{HOME}/.ubic.cfg") {
        $file_settings = Ubic::Settings::ConfigFile->read("$ENV{HOME}/.ubic.cfg");
    }
    elsif (-e "/etc/ubic/ubic.cfg") {
        $file_settings = Ubic::Settings::ConfigFile->read("/etc/ubic/ubic.cfg");
    }
    return $file_settings;
}

sub _env_settings {
    return {
        ($ENV{UBIC_SERVICE_DIR} ? (service_dir => $ENV{UBIC_SERVICE_DIR}) : ()),
        ($ENV{UBIC_DIR} ? (data_dir => $ENV{UBIC_DIR}) : ()),
        ($ENV{UBIC_DEFAULT_USER} ? (default_user => $ENV{UBIC_DEFAULT_USER}) : ()),
    };
}

sub _load {
    return $settings if $settings;

    my $file_settings = _file_settings;
    my $env_settings = _env_settings;

    $settings = {
        %$file_settings,
        %$env_settings,
    };

    unless (keys %$settings) {
        die "ubic is not configured, run 'ubic-admin setup' first\n";
    }
    for (qw/ service_dir data_dir default_user /) {
        unless (defined $settings->{$_}) {
            die "incomplete ubic configuration, setting '$_' is not defined";
        }
    }

    return $settings;
}

sub service_dir {
    my ($class, $value) = validate_pos(@_, 1, 0);
    if (defined $value) {
        $ENV{UBIC_SERVICE_DIR} = $value;
        undef $settings;
        return;
    }
    return _load->{service_dir};
}

sub data_dir {
    my ($class, $value) = validate_pos(@_, 1, 0);
    if (defined $value) {
        $ENV{UBIC_DIR} = $value;
        undef $settings;
        return;
    }
    return _load->{data_dir};
}

sub default_user {
    my ($class, $value) = validate_pos(@_, 1, 0);
    if (defined $value) {
        $ENV{UBIC_DEFAULT_USER} = $value;
        undef $settings;
        return;
    }
    return _load->{default_user};
}

sub check_settings {
    _load;
}


1;

__END__
=pod

=head1 NAME

Ubic::Settings - ubic settings

=head1 VERSION

version 1.32_02

=head1 SYNOPSIS

    my $service_dir = Ubic::Settings->service_dir;
    my $data_dir = Ubic::Settings->data_dir;
    my $default_user = Ubic::Settings->default_user;

    Ubic::Settings->data_dir($new_dir);

=head1 DESCRIPTION

This module can be used to get common ubic settings: I<service_dir>, I<data_dir> and I<default_user>.

Note that these settings are global and used by ubic core. Services don't have to use I<data_dir> to store their data, for example; they can use any dir they want.

Settings are determined in the following order (from the most priority to the least):

=over

=item *

Overrides via C<data_dir()>, C<service_dir()> and C<default_user()> methods.

=item *

Environment variables I<UBIC_SERVICE_DIR>, I<UBIC_DIR> and I<UBIC_DEFAULT_USER> (which affect accordingly I<service_dir>, I<data_dir> and I<default_user>);

=item *

Config file at I<~/.ubic.cfg>, if it exists;

=item *

Config file at I</etc/ubic/ubic.cfg>, if it exists and config file in home directory doesn't exist.

=back

=head1 INTERFACE SUPPORT

This is considered to be a public class. Any changes to its interface will go through a deprecation cycle.

=head1 METHODS

If any of setting methods is called with new value, this value will be applied for current process only.

They also will be propagated to future child processes via environment variables.

=over

=item B<service_dir()>

=item B<service_dir($dir)>

Get or set directory with service descriptions.

=item B<data_dir()>

=item B<data_dir($dir)>

Get or set directory into which ubic stores all of its data (locks, status files, tmp files).

=item B<default_user()>

=item B<default_user($user)>

Get or set user for services which don't specify user themselves.

=item B<check_settings()>

Check if all settings are valid.

Will throw an exception if any configuration options are not set.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

