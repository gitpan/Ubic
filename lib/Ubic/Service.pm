package Ubic::Service;
{
  $Ubic::Service::VERSION = '1.36_02';
}

use strict;
use warnings;

use Ubic::Settings;

# ABSTRACT: interface and base class for any ubic service


use Ubic::Result qw(result);

sub start {
    die "not implemented";
}

sub stop {
    die "not implemented";
}

sub status {
    my ($self) = @_;
    die "not implemented";
}

sub reload {
    my ($self) = @_;
    return result('unknown', 'not implemented');
}

sub port {
    my ($self) = @_;
    return; # by default, service has no port
}

sub user {
    my $self = shift;
    return Ubic::Settings->default_user;
}

sub group {
    return ();
}

sub check_period {
    my ($self) = @_;
    return 60;
}

sub check_timeout {
    return 60;
}

sub custom_commands {
    return ();
}

sub do_custom_command {
    die "No such command";
}

sub name($;$) {
    my ($self, $name) = @_;
    if (defined $name) {
        $self->{name} = $name;
    }
    else {
        return $self->{name};
    }
}

sub full_name($) {
    my ($self) = @_;
    my $parent_name = $self->parent_name;
    if (defined $parent_name) {
        return $parent_name.".".$self->name;
    }
    else {
        return $self->name;
    }
}

sub parent_name($;$) {
    my ($self, $name) = @_;
    if (defined $name) {
        $self->{parent_name} = $name;
    }
    else {
        return $self->{parent_name};
    }
}


1;

__END__
=pod

=head1 NAME

Ubic::Service - interface and base class for any ubic service

=head1 VERSION

version 1.36_02

=head1 SYNOPSIS

    print "Service: ", $service->name;
    $service->start;
    $service->stop;
    $service->restart;
    $status = $service->status;

=head1 DESCRIPTION

Ubic::Service is the abstract base class for all ubic service classes.

It provides common API for implementing service start/stop operations, custom commands and tuning some metadata properties (C<user()>, C<group()>, C<check_period()>).

=head1 METHODS

=head2 ACTION METHODS

All action methods should return L<Ubic::Result::Class> objects. If action method returns plain string, L<Ubic> will wrap it into result object too.

=over

=item B<start()>

Start service. Should throw exception on failure and string with operation result otherwise.

Starting already running service should do nothing and return C<already running>.

=item B<stop()>

Stop service. Should throw exception on failure and string with operation result otherwise.

Stopping already stopped service should do nothing and return C<not running>.

Successful stop of a service B<must> disable this service.

=item B<status()>

Check real status of service.

It should check that service is running correctly and return C<running> if it is so.

=item B<reload()>

Reload service, if possible.

=back

=head2 METADATA METHODS

All metadata methods are read-only. All of them provide sane defaults.

=over

=item B<port()>

Get port number if service provides a server which uses TCP protocol.

Default is C<undef>.

=item B<user()>

Should return user from which the service can be controlled and will be running.

Defaults to C<default_user> from L<Ubic::Settings> (i.e., C<root> for system-wide installations, or to the installation owner for local installations).

=item B<group()>

Get list of groups from which the service can be controlled and will be running.

First group from list will be used as real and effective group id, and other groups will be set as supplementary groups.

Default is an empty list, which will later be interpreted as default group of the user returned by C<user()> method.

=item B<check_period()>

Period of checking a service by watchdog in seconds.

Default is 60 seconds and it is unused by ubic-watchdog currently, so don't bother to override it by now :)

=item B<check_timeout()>

Timeout after which watchdog will give up on checking a service and kill itself.

This parameter exists as a precaution against incorrectly implemented C<status()> or C<start()> methods. If C<status()> method hangs, without this timeout, watchdog would stay in memory forever and never get a chance to restart a service.

This parameter is *not* a timeout for querying your service by HTTP or whatever your status check is. Service-specific timeouts should be configured by other means.

Default value is 60 seconds. It should not be changed unless you have a very good reason to do so (i.e., your service is so horribly slow that it can't start in 1 minute).

=back

=head2 CUSTOM COMMAND METHODS

Services can define custom commands which don't fit into usual C<start/stop/restart/status> set.

=over

=item B<custom_commands()>

Can return list of service's custom commands, if such are exist.

=item B<do_custom_command($command)>

Should execute specified command, if it is supported.

=back

=head2 NAME METHODS

These methods usually should not be overriden by service classes. They are usually used by code which loads service (i.e. some L<Ubic::Multiservice>) to associate service with its name.

=over

=item B<name()>

=item B<name($new_name)>

Name of service.

Each service with the same parent should have an unique name.

In case of subservices, this method should return the most lower-level name.

Service implementation classes shouldn't override this or other C<*_name> methods; it's usually a service's loader job to set them correctly.

=item B<full_name()>

Fully qualified name of service.

Each service must have a unique full_name.

Full name is a concatenation of service's short C<name> and service's <parent_name>.

=item B<parent_name()>

=item B<parent_name($new_parent_name)>

Get/set name of service's parent.

Service's loader (i.e. some kind of L<Ubic::Multiservice>) is responsible for calling this method immediately after service's construction as C<< $service->parent_name($self->full_name) >>.

=back

=head1 FUTURE DIRECTIONS

Current API for custom commands is inconvenient and don't support parameterized commands. It needs some refactoring.

Requiring every service to inherit from this class can be seen as undesirable by some programmers, especially by those who prefer to use Moose and roles.
If you know how to make this API more role-friendly without too much of converting pains, please contact us at ubic-perl@googlegroups.com or at irc://irc.perl.org#ubic.

=head1 SEE ALSO

L<Ubic::Service::Skeleton> - implement simple start/stop/status methods, and ubic will care about everything else.

L<Ubic::Service::Common> - just like Skeleton, but all code can be passed to constructor as sub references.

L<Ubic::Service::SimpleDaemon> - give it any binary and it will make service from it.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

