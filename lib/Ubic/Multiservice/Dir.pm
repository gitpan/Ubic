package Ubic::Multiservice::Dir;
BEGIN {
  $Ubic::Multiservice::Dir::VERSION = '1.31';
}

use strict;
use warnings;

# ABSTRACT: multiservice which uses directory with configs to instantiate services

use parent qw(Ubic::Multiservice);
use Params::Validate qw(:all);
use Carp;
use File::Basename;
use Scalar::Util qw(blessed);

sub new($$) {
    my $class = shift;
    my ($dir) = validate_pos(@_, 1);
    return bless { service_dir => $dir } => $class;
}

sub has_simple_service($$) {
    my $self = shift;
    my ($name) = validate_pos(@_, {type => SCALAR, regex => qr/^[\w.-]+$/});
    return(-e "$self->{service_dir}/$name");
}

my $eval_id = 1;
sub simple_service($$) {
    my $self = shift;
    my ($name) = validate_pos(@_, {type => SCALAR, regex => qr/^[\w.-]+$/});

    my $file = "$self->{service_dir}/$name";
    if (-d $file) {
        # directory => multiservice
        my $service = Ubic::Multiservice::Dir->new($file);
        $service->name($name);
        return $service;
    }
    elsif (-e $file) {
        open my $fh, '<', $file or die "Can't open $file: $!";
        my $content = do { local $/; <$fh> };
        close $fh or die "Can't close $file: $!";

        $content = "# line 1 $file\n$content";
        $content = "package UbicService".($eval_id++).";\n# line 1 $file\n$content";
        my $service = eval $content;
        if ($@) {
            die "Failed to eval '$file': $@";
        }
        unless (blessed $service) {
            die "$file doesn't contain any service";
        }
        unless ($service->isa('Ubic::Service')) {
            die "$file returned $service instead of Ubic::Service";
        }
        unless (defined $service->name) {
            $service->name($name);
        }
        return $service;
    }
    else {
        croak "Service '$name' not found";
    }
}

sub service_names($) {
    my $self = shift;

    my @names;
    for my $file (glob("$self->{service_dir}/*")) {
        next unless -f $file or -d $file;
        $file = basename($file);

        # we skip files with dots, for example old debian configs like my-service.dpkg-old
        next if $file !~ /^[\w-]+$/;

        push @names, $file;
    }
    return @names;
}


1;


__END__
=pod

=head1 NAME

Ubic::Multiservice::Dir - multiservice which uses directory with configs to instantiate services

=head1 VERSION

version 1.31

=head1 METHODS

=over

=item B<< new($dir) >>

Constructor.

=back

=head1 SEE ALSO

L<Ubic::Multiservice> - base interface of this class.

L<Ubic> - main ubic module uses this class as root namespace of services.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

