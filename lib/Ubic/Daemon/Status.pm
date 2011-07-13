package Ubic::Daemon::Status;
BEGIN {
  $Ubic::Daemon::Status::VERSION = '1.32_01';
}

use strict;
use warnings;

# ABSTRACT: daemon status structure


use Params::Validate;

sub new {
    my $class = shift;
    my $params = validate(@_, {
        pid => 1,
    });
    return bless $params => $class;
}

sub pid {
    my $self = shift;
    validate_pos(@_);
    return $self->{pid};
}


1;

__END__
=pod

=head1 NAME

Ubic::Daemon::Status - daemon status structure

=head1 VERSION

version 1.32_01

=head1 SYNOPSIS

    say $status->pid;

=head1 METHODS

=over

=item B<< new($options) >>

Constructor. Should be called from L<Ubic::Daemon> only.

=item B<< pid() >>

Get daemon's PID.

=back

=head1 SEE ALSO

L<Ubic::Daemon> - general process daemonizator

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

