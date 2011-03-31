package Ubic::Credentials::OS::Windows;
BEGIN {
  $Ubic::Credentials::OS::Windows::VERSION = '1.25';
}

use strict;
use warnings;

use parent qw(Ubic::Credentials);

BEGIN {
    return if $^O ne 'MSWin32';

    require Win32::pwent;
    push @Win32::pwent::EXPORT_OK, 'endgrent';
    Win32::pwent->import( qw( getpwent endpwent setpwent getpwnam getpwuid getgrent endgrent setgrent getgrnam getgrgid ) );
}

sub new {
    my $class = shift;
    return bless {} => $class;
}

sub set_effective {}
sub reset_effective {}
sub eq { 1 }
sub set {}

1;


__END__
=pod

=head1 NAME

Ubic::Credentials::OS::Windows

=head1 VERSION

version 1.25

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

