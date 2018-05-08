package Koha::Contrib::ARK::Writer;
# ABSTRACT: Write biblio records into Koha Catalog
use Moose;

with 'MooseX::RW::Writer';

use Modern::Perl;
use C4::Biblio;


=attr ark

L<Koha::Contrib::ARK> object.

=cut
has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


sub write {
    my ($self, $br) = @_;
    my ($biblionumber, $record) = @$br;

    return unless $record;

    if ($self->ark->doit) {
        my $fc = GetFrameworkCode($biblionumber);
        ModBiblio( $record->as('Legacy'), $biblionumber, $fc );
    }
    $self->ark->log->debug("BIBLIO AFTER PROCESSING:\n", $record->as('Text'));
}


1;
