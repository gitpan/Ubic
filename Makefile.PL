
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'flexible perl-based service manager',
  'AUTHOR' => 'Vyacheslav Matyukhin <mmcleric@yandex-team.ru>',
  'BUILD_REQUIRES' => {
    'Cwd' => '0',
    'File::Find' => '0',
    'Test::Class' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0',
    'Test::TCP' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Ubic',
  'EXE_FILES' => [
    'bin/ubic-watchdog',
    'bin/ubic',
    'bin/ubic-admin',
    'bin/ubic-periodic',
    'bin/ubic-update',
    'bin/ubic-daemon'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Ubic',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::Accessor::Fast' => '0',
    'Config' => '0',
    'Data::Dumper' => '0',
    'Exporter' => '0',
    'Fcntl' => '0',
    'File::Basename' => '0',
    'Getopt::Long' => '2.33',
    'HTTP::Server::Simple::CGI' => '0',
    'IO::Handle' => '0',
    'IPC::Open3' => '0',
    'JSON' => '0',
    'LWP::UserAgent' => '0',
    'List::MoreUtils' => '0',
    'List::Util' => '0',
    'POSIX' => '0',
    'Params::Validate' => '0',
    'Pod::Usage' => '0',
    'Scalar::Util' => '0',
    'Storable' => '0',
    'Term::ANSIColor' => '0',
    'Time::HiRes' => '0',
    'Try::Tiny' => '0',
    'overload' => '0',
    'parent' => '0'
  },
  'VERSION' => '1.33_02',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



