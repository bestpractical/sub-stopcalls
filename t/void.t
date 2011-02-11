#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok('Sub::StopCalls');
#use B::Concise ();

my $i = 0;

sub foo {
    $i++;
    return Sub::StopCalls::stop(qw(foo bar baz));
}

my @subs = (
sub {
    foo();
    return 1;
},
sub {
    my $x = 1;
    foo( 'boo', $x );
    return 1;
},
);

foreach my $sub (@subs) {
    my $cur = $i;
#    B::Concise::compile($sub)->();
    $sub->();
#    B::Concise::compile($sub)->();
    is( $i, $cur + 1 );
    $sub->();
    is( $i, $cur + 1 );
}
