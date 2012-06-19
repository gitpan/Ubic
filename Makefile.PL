
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "polymorphic service manager",
  "AUTHOR" => "Vyacheslav Matyukhin <mmcleric\@yandex-team.ru>",
  "BUILD_REQUIRES" => {
    "Cwd" => 0,
    "File::Find" => 0,
    "Test::Class" => 0,
    "Test::Fatal" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Ubic",
  "EXE_FILES" => [
    "bin/ubic",
    "bin/ubic-admin",
    "bin/ubic-daemon",
    "bin/ubic-periodic",
    "bin/ubic-update",
    "bin/ubic-watchdog"
  ],
  "LICENSE" => "perl",
  "NAME" => "Ubic",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Accessor::Fast" => 0,
    "Config" => 0,
    "Config::Tiny" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "Fcntl" => 0,
    "File::Basename" => 0,
    "File::Path" => 0,
    "Getopt::Long" => "2.33",
    "HTTP::Server::Simple::CGI" => 0,
    "IO::Handle" => 0,
    "IO::Socket" => 0,
    "IPC::Open3" => 0,
    "JSON" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "POSIX" => 0,
    "Params::Validate" => 0,
    "Pod::Usage" => 0,
    "Scalar::Util" => 0,
    "Storable" => 0,
    "Term::ANSIColor" => 0,
    "Time::HiRes" => 0,
    "Try::Tiny" => 0,
    "overload" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.43_02",
  "test" => {
    "TESTS" => "t/*.t t/loaders/*.t t/multiservice/*.t"
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



