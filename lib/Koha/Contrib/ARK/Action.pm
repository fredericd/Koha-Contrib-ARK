package Koha::Contrib::ARK::Action;
# ABSTRACT: ARK Action roles

use Moose::Role;
use Modern::Perl;

requires 'action';

=attr ark

L<Koha::Contrib::ARK> object.

=cut
has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


=method action($biblionumber, $record)

Do something with Koha biblio record.

=cut
sub action {
    my $self = shift;

    say "action on ARK";
}

1;
