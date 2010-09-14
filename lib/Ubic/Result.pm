package Ubic::Result;
BEGIN {
  $Ubic::Result::VERSION = '1.19';
}

use strict;
use warnings;

# ABSTRACT: common return value for many ubic interfaces


use Ubic::Result::Class;
use Scalar::Util qw(blessed);
use parent qw(Exporter);

our @EXPORT_OK = qw(
    result
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

sub result {
    my ($str, $msg) = @_;
    if (blessed $str and $str->isa('Ubic::Result::Class')) {
        return $str;
    }
    return Ubic::Result::Class->new({ type => "$str", msg => $msg });
}


1;


__END__
=pod

=head1 NAME

Ubic::Result - common return value for many ubic interfaces

=head1 VERSION

version 1.19

=head1 SYNOPSIS

    use Ubic::Result qw(:all);

    sub start {
        ...
        return result('broken', 'permission denied');
        ...
        return result('running');
        ...
        return 'already running';
    }

=head1 FUNCTIONS

=over

=item C<result($type, $optional_message)>

Construct C<Ubic::Result::Class> instance.

=back

=head1 SEE ALSO

L<Ubic::Result::Class> - result instance.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

