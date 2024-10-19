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
    my ($self, $biblio, $record) = @_;

    return unless $record;

    my $a = $self->ark;
    if ($a->doit) {
        ModBiblio( $record->as('Legacy'), $biblio->biblionumber, $biblio->frameworkcode);
    }
    $a->current->{after} = Koha::Contrib::ARK::tojson($record)
        if $a->debug;
}


1;
