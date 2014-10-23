package Ubic::Daemon::OS::Linux;
BEGIN {
  $Ubic::Daemon::OS::Linux::VERSION = '1.25';
}

use strict;
use warnings;

use POSIX;

use parent qw(Ubic::Daemon::OS);

sub pid2guid {
    my ($self, $pid) = @_;

    unless (-d "/proc/$pid") {
        return; # process not found
    }
    my $opened = open(my $fh, '<', "/proc/$pid/stat");
    unless ($opened) {
        # open failed
        my $error = $!;
        unless (-d "/proc/$pid") {
            return; # process exited right now
        }
        die "Open /proc/$pid/stat failed: $!";
    }
    my $line = <$fh>;
    my @fields = split /\s+/, $line;
    my $guid = $fields[21];
    return $guid;
}

sub pid2cmd {
    my ($self, $pid) = @_;

    open my $daemon_cmd_fh, '<', "/proc/$pid/cmdline" or die "Can't open daemon's cmdline: $!";
    my $daemon_cmd = <$daemon_cmd_fh>;
    $daemon_cmd =~ s/\x{00}$//;
    $daemon_cmd =~ s/\x{00}/ /g;
    close $daemon_cmd_fh;
}

sub close_all_fh {
    my ($self, @except) = @_;

    my @fd_nums = map { s!^.*/!!; $_ } glob("/proc/$$/fd/*");
    for my $fd (@fd_nums) {
        next if grep { $_ == $fd } @except;
        POSIX::close($fd);
    }
}

sub pid_exists {
    my ($self, $pid) = @_;
    return (-d "/proc/$pid");
}

1;

__END__
=pod

=head1 NAME

Ubic::Daemon::OS::Linux

=head1 VERSION

version 1.25

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

