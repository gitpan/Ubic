package Ubic::UA;
{
  $Ubic::UA::VERSION = '1.56';
}

# ABSTRACT: tiny http client


use strict;
use warnings;
use IO::Socket;

sub new {
    my $class = shift;
    my %arg   = @_;

    my $self = {};
    $self->{timeout} = $arg{timeout} || 10;
    return bless $self => $class;
}

sub get {
    my $self = shift;
    my ($url) = @_;

    unless ($url) {
        return { error => 'Url not specified' };
    }

    my ($scheme, $authority, $path, $query, undef) = $url
    =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;

    my $socket = IO::Socket::INET->new(
        PeerAddr => $authority,
        Proto    => 'tcp',
        Timeout  => $self->{timeout}
    ) or return {error => $@};
    $socket->autoflush(1);
    $path .= '?' . $query if $query;
    print $socket "GET $path HTTP/1.0\r\n\r\n";
    my @arr = <$socket>;
    close $socket;

    my $status_line = shift @arr;
    my @headers;
    while (my $line = shift @arr) {
        last if $line eq "\r\n";
        $line =~ s/\r\n//;
        push @headers, $line;
    }

    if ($status_line =~ /^HTTP\/([0-9\.]+)\s+([0-9]{3})\s+(?=([^\r\n]*))?/i) {
        my ($ver, $code, $status) = ($1, $2, $3);
        return {
            ver => $ver,
            code => $code,
            status => $status,
            body => join('', @arr),
            headers => \@headers,
        };
    }
    else {
        return { error => 'Invalid http response' };
    }
}


1;

__END__

=pod

=head1 NAME

Ubic::UA - tiny http client

=head1 VERSION

version 1.56

=head1 DESCRIPTION

This module is a tiny and horribly incomplete http useragent implementetion.

It's used by L<Ubic::Ping::Service> and it allows ubic to avoid dependency on LWP.

=head1 INTERFACE SUPPORT

This is considered to be a non-public class. Its interface is subject to change without notice.

=head1 METHODS

=over

=item B<< new(timeout => $timeout) >>

Construct new useragent.

=item B<< get($url) >>

Fetch a given url.

Returns a hashref with I<body>, I<status> and some others and some other fields.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
