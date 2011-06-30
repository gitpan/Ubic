package Ubic::Ping::Service;
BEGIN {
  $Ubic::Ping::Service::VERSION = '1.31';
}

# ABSTRACT: ubic.ping service

use strict;
use warnings;

use Ubic::Service::Common;
use Ubic::Daemon qw(:all);
use Ubic::Result qw(result);
use LWP::UserAgent;
use POSIX;
use Time::HiRes qw(sleep);

use Ubic::Settings;

use Config;

sub new {
    # ugly; waiting for druxa's Mopheus to save us all...
    my $port = $ENV{UBIC_SERVICE_PING_PORT} || 12345;
    my $pidfile = Ubic::Settings->data_dir."/ubic-ping.pid";
    my $log = $ENV{UBIC_SERVICE_PING_LOG} || '/dev/null';

    my $perl = $Config{perlpath};

    Ubic::Service::Common->new({
        start => sub {
            my $pid;
            start_daemon({
                bin => qq{$perl -MUbic::Ping -e 'Ubic::Ping->new($port)->run;'},
                name => 'ubic.ping',
                pidfile => $pidfile,
                stdout => $log,
                stderr => $log,
                ubic_log => $log,
            });
        },
        stop => sub {
            stop_daemon($pidfile);
        },
        status => sub {
            my $daemon = check_daemon($pidfile);
            unless ($daemon) {
                return 'not running';
            }
            my $ua = LWP::UserAgent->new(timeout => 1);
            my $response = $ua->get("http://localhost:$port/ping");
            unless ($response->is_success) {
                return result('broken', $response->status_line);
            }
            my $result = $response->decoded_content;
            if ($result =~ /^ok$/) {
                return result('running', "pid ".$daemon->pid);
            }
            else {
                return result('broken', $result);
            }
        },
        port => $port,
        timeout_options => { start => { step => 0.1, trials => 3 }},
    });
}


1;

__END__
=pod

=head1 NAME

Ubic::Ping::Service - ubic.ping service

=head1 VERSION

version 1.31

=head1 INTERFACE SUPPORT

This is considered to be a non-public class. Its interface is subject to change without notice.

=head1 METHODS

=over

=item B<< new() >>

Constructor.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

