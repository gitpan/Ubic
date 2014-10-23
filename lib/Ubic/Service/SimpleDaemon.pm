package Ubic::Service::SimpleDaemon;
BEGIN {
  $Ubic::Service::SimpleDaemon::VERSION = '1.28';
}

use strict;
use warnings;

# ABSTRACT: variant of service when your service is simple daemonized binary


use parent qw(Ubic::Service::Skeleton);

use Ubic::Daemon qw(start_daemon stop_daemon check_daemon);
use Ubic::Result qw(result);
use Ubic::Settings;

use Params::Validate qw(:all);

# Beware - this code will ignore any overrides if you're using custom Ubic->new(...) objects
our $PID_DIR;

sub _pid_dir {
    return $PID_DIR if defined $PID_DIR;
    if ($ENV{UBIC_DAEMON_PID_DIR}) {
        warn "UBIC_DAEMON_PID_DIR env variable is deprecated, use Ubic->set_data_dir or configs instead (see Ubic::Settings for details)";
        $PID_DIR = $ENV{UBIC_DAEMON_PID_DIR};
    }
    else {
        $PID_DIR = Ubic::Settings->data_dir."/simple-daemon/pid";
    }
    return $PID_DIR;
}

sub new {
    my $class = shift;
    my $params = validate(@_, {
        bin => { type => SCALAR | ARRAYREF },
        user => { type => SCALAR, optional => 1 },
        group => { type => SCALAR | ARRAYREF, optional => 1 },
        name => { type => SCALAR, optional => 1 },
        stdout => { type => SCALAR, optional => 1 },
        stderr => { type => SCALAR, optional => 1 },
        ubic_log => { type => SCALAR, optional => 1 },
    });

    return bless {%$params} => $class;
}

sub pidfile {
    my ($self) = @_;
    my $name = $self->full_name or die "Can't start nameless SimpleDaemon";
    return _pid_dir."/$name";
}

sub start_impl {
    my ($self) = @_;
    my $start_params = {
        pidfile => $self->pidfile,
        bin => $self->{bin},
        stdout => $self->{stdout} || "/dev/null",
        stderr => $self->{stderr} || "/dev/null",
        ubic_log => $self->{ubic_log} || "/dev/null",
    };
    if ($self->{user}) {
        $start_params->{user} = $self->{user}; # do we actually need this? Ubic.pm should call setuid for us...
    }
    start_daemon($start_params);
}

sub user {
    my $self = shift;
    return $self->{user} if defined $self->{user};
    return $self->SUPER::user();
}

sub group {
    my $self = shift;
    my $groups = $self->{group};
    return $self->SUPER::group() if not defined $groups;
    return @$groups if ref $groups eq 'ARRAY';
    return $groups;
}

sub stop_impl {
    my ($self) = @_;
    stop_daemon($self->pidfile);
}

sub status_impl {
    my ($self) = @_;
    if (my $daemon = check_daemon($self->pidfile)) {
        return result('running', "pid ".$daemon->pid);
    }
    else {
        return result('not running');
    }
}


1;


__END__
=pod

=head1 NAME

Ubic::Service::SimpleDaemon - variant of service when your service is simple daemonized binary

=head1 VERSION

version 1.28

=head1 SYNOPSIS

    use Ubic::Service::SimpleDaemon;
    my $service = Ubic::Service::SimpleDaemon->new({
        name => "sleep",
        bin => "sleep 1000",
    });

=head1 DESCRIPTION

Unlike L<Ubic::Service::Common>, this class allows you to specify only name and binary of your service.

=head1 METHODS

=over

=item B<< new($params) >>

Constructor.

Parameters:

=over

=item I<bin>

Daemon binary.

=item I<name>

Service's name.

Optional, will usually be set by upper-level multiservice. Don't set it unless you know what you're doing.

=item I<user>

User under which daemon will be started. Optional, default is C<root>.

=item I<group>

Group under which daemon will be started. Optional, default is all user groups.

Value can be scalar or arrayref.

=item I<stdout>

File into which daemon's stdout will be redirected. Default is C</dev/null>.

=item I<stderr>

File into which daemon's stderr will be redirected. Default is C</dev/null>.

=back

=item B<< pidfile() >>

Get pid filename. It will be concatenated from simple-daemon pid dir and service's name.

=back

=head1 SEE ALSO

L<Ubic::Daemon> - module to daemonize any binary

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

