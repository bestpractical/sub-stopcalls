#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use No::Calls;

my $i = 0;

sub foo {
    $i++;
    return No::Calls::no_more_calls();
}

sub bar {
    
    foo();

    return 1;
}

bar();
is( $i, 1 );
bar();
is( $i, 1 );

