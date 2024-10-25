package Koha::Contrib::ARK::Writer;
# ABSTRACT: Write biblio records into Koha Catalog

use Moose;
use Modern::Perl;
use C4::Biblio qw/ ModBiblio /;

with 'MooseX::RW::Writer';


=attr ark

L<Koha::Contrib::ARK> object.

=cut
has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


sub write {
    my $self = shift;

    my $ark = $self->ark;
    return unless $ark->doit;

    my $current = $ark->current;
    my $biblio = $current->{biblio};
    my $record = $biblio->{record};

    return unless $record;

    ModBiblio(
        $record->as('Legacy'),
        $biblio->biblionumber,
        $biblio->frameworkcode
    );
}


1;
