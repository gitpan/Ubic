package Ubic::Daemon::PidState;
{
  $Ubic::Daemon::PidState::VERSION = '1.57_01';
}

use strict;
use warnings;

# ABSTRACT: internal object representing process info stored on disk


use Params::Validate qw(:all);
use Ubic::Lockf;
use Ubic::AtomicFile;

use overload '""' => sub {
    my $self = shift;
    return $self->{dir};
};

sub new {
    my $class = shift;
    my ($dir) = validate_pos(@_, { type => SCALAR });
    return bless { dir => $dir } => $class;
}

sub is_empty {
    my ($self) = validate_pos(@_, 1);
    my $dir = $self->{dir};

    return if not -d $dir and -s $dir; # old-style pidfile
    return if -d $dir and -s "$dir/pid"; # non-empty new-style pidfile

    return 1;
}

sub init {
    my ($self) = validate_pos(@_, 1);
    my $dir = $self->{dir};
    if (-e $dir and not -d $dir) {
        print "converting $dir to dir\n";
        unlink $dir or die "Can't unlink $dir: $!";
    }
    unless (-d $dir) {
        mkdir $dir or die "Can't create $dir: $!";
    }

}

sub read {
    my ($self) = validate_pos(@_, 1);

    my $dir = $self->{dir};

    my $content;
    my $parse_content = sub {
        if ($content =~ /\A pid \s+ (\d+) \n guid \s+ (.+) (?: \n daemon \s+ (\d+) )? \Z/x) {
            # new format
            return { pid => $1, guid => $2, daemon => $3, format => 'new' };
        }
        elsif ($content eq '') {
            # file is empty, probably lost after reboot - we didn't sync() pidfile to disk in old versions
            return;
        }
        else {
            # We consider invalid pidfile content as the fatal, unrecoverable error.
            # Please report all cases of invalid pidfile as critical issues.
            #
            # (This policy will be changed if ubic become popular enough for this to annoy enough people,
            # but collecting bugreports about weird stuff happening is more important by now.)
            die "invalid pidfile content in pidfile $dir";
        }
    };
    if (-d $dir) {
        # pidfile as dir
        my $open_success = open my $fh, '<', "$dir/pid";
        unless ($open_success) {
            if ($!{ENOENT}) {
                return; # pidfile not found, daemon is not running
            }
            else {
                die "Failed to open '$dir/pid': $!";
            }
        }
        $content = join '', <$fh>;
        return $parse_content->();
    }
    else {
        # deprecated - single pidfile without dir
        if (-f $dir and not -s $dir) {
            return; # empty pidfile - old way to stop services
        }
        open my $fh, '<', $dir or die "Failed to open $dir: $!";
        $content = join '', <$fh>;
        if ($content =~ /\A (\d+) \Z/x) {
            # old format
            return { pid => $1, format => 'old' };
        }
        else {
            return $parse_content->();
        }
    }
}

sub lock {
    my ($self, $timeout) = validate_pos(@_, 1, { type => SCALAR, default => 0 });

    my $dir = $self->{dir};
    if (-d $dir) {
        # new-style pidfile
        return lockf("$dir/lock", { timeout => $timeout });
    }
    else {
        return lockf($dir, { blocking => 0 });
    }
}

sub remove {
    my ($self) = validate_pos(@_, 1);
    my $dir = $self->{dir};

    if (-d $dir) {
        if (-e "$dir/pid") {
            unlink "$dir/pid" or die "Can't remove $dir/pid: $!";
        }
    }
    else {
        unlink $dir or die "Can't remove $dir: $!";
    }
}

sub write {
    my $self = shift;
    my $dir = $self->{dir};
    unless (-d $dir) {
        die "piddir $dir not initialized";
    }
    my $params = validate(@_, {
        pid => 1,
        guid => 1,
    });

    my ($pid, $guid) = @$params{qw/ pid guid /};
    my $self_pid = $$;

    my $content =
        "pid $self_pid\n".
        "guid $guid\n".
        "daemon $pid\n";
    Ubic::AtomicFile::store( $content => "$dir/pid" );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Daemon::PidState - internal object representing process info stored on disk

=head1 VERSION

version 1.57_01

=head1 INTERFACE SUPPORT

This is considered to be a non-public class. Its interface is subject to change without notice.

=head1 METHODS

=over

=item B<new()>

Constructor. Does nothing by itself, doesn't read pidfile and doesn't try to create pid dir.

=item B<is_empty()>

Check if pid dir doesn't exist yet.

=item B<init()>

Create pid dir. After this method is called, C<is_empty()> will start to return false value.

=item B<read()>

Read daemon info from pidfile.

Returns undef if pidfile not found. Throws exceptions when content is invalid.

=item B<lock()>
=item B<lock($timeout)>

Acquire piddir lock. Lock will be nonblocking unless 'timeout' parameter is set.

=item B<remove()>

Remove the pidfile from the piddir. C<is_empty()> will still return false.

This method should be called only after lock is acquired via C<lock()> method (TODO - check before removing?).

=item B<write({ pid => $pid, guid => $guid })>

Write guardian pid and guid into the pidfile.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
