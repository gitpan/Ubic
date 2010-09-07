package Ubic::Run;
BEGIN {
  $Ubic::Run::VERSION = '1.16';
}

use strict;
use warnings;

# ABSTRACT: really simple way to write init scripts


use Ubic::Cmd;
use Getopt::Long;
use Pod::Usage;

sub import {
    my ($name) = $0 =~ m{^/etc/init\.d/(.+)$} or die "Strange $0";
    my $force;
    GetOptions(
        'f|force' => \$force,
    ) or die "Unknown option specified";

    my ($command, @args) = @ARGV;
    my @names;
    if (@args) {
        @names = map { "$name.$_" } @args;
    }
    else {
        @names = ($name);
    }
    Ubic::Cmd->run({
        name => \@names,
        ($command ? (command => $command) : ()),
        ($force ? (force => $force) : ()),
    });
}

1;

__END__
=pod

=head1 NAME

Ubic::Run - really simple way to write init scripts

=head1 VERSION

version 1.16

=head1 SYNOPSIS

    # /etc/init.d/something:
    use Ubic::Run; # that's all!

=head1 AUTHOR

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

