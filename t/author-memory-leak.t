#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings;

use Test::More;
BEGIN {
    plan skip_all => 'memory leak test is linux-specific' unless $^O eq 'linux';
}

plan tests => 2;

use lib 'lib';

use t::Utils;
rebuild_tfiles();

use Ubic;
Ubic->set_data_dir('tfiles/ubic');
Ubic->set_service_dir('t/service');

# These tests check that ubic-ping don't waste memory in long runs.
# Ubic compiles service descriptions on-the-fly, every time with new package name, so memory leaks are possible.
# They happened before and can come back again after some unfortunate refactoring...
# (currently, Ubic caches every service instance forever, though, and ubic-ping don't compile simple services at all, just multiservices).

sub mem_usage {
    my $stat = slurp("/proc/$$/statm");
    my ($mem) = $stat =~ /^(\d+)/;
    return $mem;
}

{
    my $check_status = sub {
        my $status = Ubic->cached_status('multi-impl.abc');
    };

    $check_status->();

    my $mem = mem_usage;
    $check_status->() for 1..10_000;

    cmp_ok(mem_usage() - $mem, '<', 10);
}

{
    my $check_status = sub {
        eval {
            my $status = Ubic->cached_status('multi-impl.broken.blah');
        };
    };

    $check_status->();

    my $mem = mem_usage;
    $check_status->() for 1..10_000;

    cmp_ok(mem_usage() - $mem, '<', 10);
}
