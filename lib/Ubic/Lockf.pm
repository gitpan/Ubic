package Ubic::Lockf;
{
  $Ubic::Lockf::VERSION = '1.57_01';
}

use strict;
use warnings;

# ABSTRACT: file locker with an automatic out-of-scope unlocking mechanism


use Fcntl qw(:flock);

use Params::Validate;
use POSIX qw(:errno_h);
use Carp;

use Ubic::Lockf::Alarm;

use parent qw(Exporter);

our @EXPORT = qw(lockf);


sub DESTROY ($) {
    my ($self) = @_;
    local $@;
    my $fh = $self->{_fh};
    return unless defined $fh; # already released or dissolved
    flock $fh, LOCK_UN;
    delete $self->{_fh}; # closes the file if opened by us
}

my %defaults = (
    shared => 0,
    blocking => 1,
    timeout => undef,
    mode => undef,
);

sub lockf ($;$) {
    my ($param, $opts) = validate_pos(@_, 1, 0);
    $opts ||= {};
    $opts = validate(@{ [ $opts ] }, {
        blocking => 0,
        shared => 0,
        silent => 0, # deprecated option, does nothing
        timeout => 0,
        mode => 0,
    });
    $opts = {%defaults, %$opts};

    my ($fh, $fname);
    if (ref $param eq "") { # filename instead of filehandle
        open $fh, ">>", $param or die "Can't open $param: $!";
        $fname = $param;
    } else {
        $fh = $param;
    }

    unless (_lockf($fh, $opts, $fname)) {
        return;
    }

    # don't check chmod success - it can fail and it's ok
    chmod ($opts->{mode}, ($fname || $fh)) if defined $opts->{mode};

    return bless {
        _fh => $fh,
        _fname => $fname,
    };
}

sub _lockf ($$;$) {
    my ($fh, $opts, $fname) = @_;
    $fname ||= ''; # TODO - discover $fname from $fh, it's possible in most cases with some /proc magic

    my $mode = ($opts->{shared} ? LOCK_SH : LOCK_EX);

    if (
        not $opts->{blocking}
        or (defined $opts->{timeout} and not $opts->{timeout}) # timeout=0
    ) {
        return 1 if flock ($fh, $mode | LOCK_NB);
        return 0 if ($! == EWOULDBLOCK);
        croak "flock ".($fname || '')." failed: $!";
    }

    unless (flock ($fh, $mode | LOCK_NB)) {
        my $msg = "$fname already locked, wait...";
        if (-t STDOUT) {
            print $msg;
        }
    } else {
        return 1;
    }

    if ($opts->{timeout}) {
        local $SIG{ALRM} = sub { croak "flock $fname failed: timed out" };
        my $alarm = Ubic::Lockf::Alarm->new($opts->{timeout});
        flock $fh, $mode or die "flock failed: $!";
    } else {
        flock $fh, $mode or die "flock failed: $!";
    }
    return 1;
}

sub name($)
{
    my $self = shift;
    return $self->{_fname};
}

sub dissolve {
    my $self = shift;
    undef $self->{_fh};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Lockf - file locker with an automatic out-of-scope unlocking mechanism

=head1 VERSION

version 1.57_01

=head1 SYNOPSIS

    use Ubic::Lockf;
    $lock = lockf($filehandle);
    $lock = lockf($filename);
    undef $lock; # unlocks either

=head1 DESCRIPTION

C<lockf> is a perlfunc C<flock> wrapper. The lock is autotamically released as soon as the associated object is
no longer referenced.

=head1 METHODS

=over

=item B<lockf($file, $options)>

Create an Lockf instance. Always save the result in some variable(s), otherwise the lock will be released immediately.

The lock is automatically released when all the references to the Lockf object are lost. The lockf mandatory parameter
can be either a string representing a filename or a reference to an already opened filehandle. The second optional
parameter is a hash of boolean options. Supported options are:

=over

=item I<shared>

OFF by default. Tells to achieve a shared lock. If not set, an exclusive lock is requested.

=item I<blocking>

ON by default. If unset, a non-blocking mode of flock is used. If this flock fails because the lock is already held by some other process,
C<undef> is returned. If the failure reason is somewhat different, permissions problems or the
absence of a target file directory for example, an exception is raised.

=item I<timeout>

Undef by default. If set, specifies the wait timeout for acquiring the blocking lock. The value of 0 is equivalent to blocking => 0 option.

=item I<mode>

Undef by default. If set, a chmod with the specified mode is performed on a newly created file. Ignored when filehandle is passed instead of a filename.

=back

=item B<name()>

Gives the name of the file, as it was when the lock was taken.

=item B<dissolve()>

Destroy lock object without unlocking.

This is useful in forking code, if you have one lock object in several processes and want to close locked fh in one process without unlocking in the other.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
