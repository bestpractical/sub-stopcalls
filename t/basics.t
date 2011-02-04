#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok('Sub::StopCalls');

my $i = 0;

sub foo {
    $i++;
    return Sub::StopCalls->stop();
}

sub void_no_args {
    foo();
    return 1;
}

sub void_with_args {
    my $x = 1;
    foo( 'boo', $x );
    return 1;
}

foreach my $func (qw(
    void_no_args
    void_with_args
) ) {
    my $ref = do { no strict; \&$func; };

    my $cur = $i;
    $ref->();
    is( $i, $cur + 1 );
    $ref->();
    is( $i, $cur + 1 );
}

