use 5.013;
use strict;
use warnings;

package Sub::StopCalls;

our $VERSION = '0.01';

use XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

Sub::StopCalls - stop sub calls (make it a constant)

=head1 SYNOPSIS

    my $i = 0;

    sub boo {
        return foo();
    }
    sub foo {
        $i++;
        return Sub::StopCalls->do();
    }

    print "$i\n"; # 0
    boo();
    print "$i\n"; # 1
    boo();
    print "$i\n"; # 1

=head1 DESCRIPTION

Module provides a way to stop further calls into a function from the current caller.

Now it's a proof of concept that works under perl 5.13.x and in void context only.

=cut

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
