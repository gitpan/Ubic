package Ubic::Service::Skeleton;
{
  $Ubic::Service::Skeleton::VERSION = '1.42';
}

use strict;
use warnings;

# ABSTRACT: skeleton of any service with common start/stop logic

use Ubic::Result qw(result);
use Scalar::Util qw(blessed);
use Time::HiRes qw(sleep);
use Ubic::Service::Utils qw(wait_for_status);

use parent qw(Ubic::Service);

sub status {
    my ($self) = @_;
    my $result = $self->status_impl;
    $result ||= 'unknown';
    $result = result($result);
    return $result;
}

sub start {
    my ($self) = @_;

    my $status = $self->status;
    if ($status->status eq 'running') {
        return 'already running'; # TODO - update $status field instead?
    }
    elsif ($status->status eq 'not running') {
        return $self->_do_start;
    }
    elsif ($status->status eq 'broken') {
        # checks inside _do_start and _do_stop guarantee correct status
        $self->_do_stop;
        return $self->_do_start;
    }
    else {
        die result('unknown', "wrong status '$status'");
    }
}

sub stop {
    my ($self) = @_;

    my $status = $self->status;
    if ($status->status eq 'not running') {
        return 'not running';
    }

    return $self->_do_stop;
}

sub status_impl {
    die 'not implemented';
}

sub start_impl {
    die 'not implemented';
}

sub stop_impl {
    die 'not implemented';
}

sub timeout_options {
    return {};
}


##### internal methods ######

sub _do_start {
    my ($self) = @_;

    my $status;

    my $start_result = $self->start_impl;
    if (blessed($start_result) and $start_result->isa('Ubic::Result::Class')) {
        $status = $start_result;
    }

    if (not $status or $status->type eq 'starting') {
        $status = wait_for_status({
            service => $self,
            expect_status => ['running', 'not running'],
            %{ $self->timeout_options->{start} || {} },
        });
        if ($status->status eq 'running') {
            $status->type('started'); # fake status to report correct action (hopefully)
        }
    }

    if (not $status) {
        die result('unknown', 'no result');
    }
    if ($status->status eq 'running') {
        return $status;
    }
    else {
        die result($status, 'start failed');
    }
}

sub _do_stop {
    my ($self) = @_;
    my $status;

    my $stop_result = $self->stop_impl;
    if (blessed($stop_result) and $stop_result->isa('Ubic::Result::Class')) {
        $status = $stop_result;
    }

    if (not $status or $status->type eq 'stopping') {
        $status = wait_for_status({
            service => $self,
            expect_status => ['not running'],
            %{ $self->timeout_options->{stop} || {} },
        });
        if ($status->status eq 'not running') {
            $status->type('stopped'); # fake status to report correct action (hopefully)
        }
    }

    if (not $status) {
        die result('unknown', 'no result');
    }
    if ($status->status eq 'not running') {
        return $status;
    }
    else {
        die result($status, 'stop failed');
    }
}

1;


__END__
=pod

=head1 NAME

Ubic::Service::Skeleton - skeleton of any service with common start/stop logic

=head1 VERSION

version 1.42

=head1 ACTIONS

=over

=item B<< status() >>

Get status of service.

Possible values: C<running>, C<not running>, C<unknown>, C<broken>.

=item B<< start() >>

Start service.

Throws exception on failure.

=item B<< stop() >>

Stop service.

Return values: C<stopped>, C<not running>.

Throws exception on failure.

=back

=head1 OVERLOADABLE METHODS

Subclass must overload following methods with simple status, start and stop implementations.

=over

=item B<status_impl>

Status implentation. Should return result object or plain string which coerces to result object.

=item B<start_impl>

Start implementation.

It can check for status itself and return proper C<Ubic::Result> value, or it can allow skeleton class to recheck status after that, in several attempts.

To choose second option, it should return non-result value or C<result("starting")>. See C<timeout_options()> method for details about recheck policy.

=item B<stop_impl>

Stop implementation.

It can check for status itself and return proper C<Ubic::Result> value, or it can allow skeleton class to recheck status after that, in several attempts.

To choose second option, it should return non-result value or C<result("stopping")>. See C<timeout_options()> method for details about recheck policy.

=item B<timeout_options>

Return hashref with timeout options.

Possible options:

=over

=item I<start>

Params to be used when checking for status of started service.

Should contain hashref with I<step> and I<trials> options for C<wait_for_status> function from C<Ubic::Service::Utils>.

=back

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

