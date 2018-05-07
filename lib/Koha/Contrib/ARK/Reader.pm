package Koha::Contrib::ARK::Reader;
# ABSTRACT: Read Koha biblio records with/without ARK
use Moose;

with 'MooseX::RW::Reader';

use Modern::Perl;
use C4::Context;
use C4::Biblio;
use MARC::Moose::Record;


=attr ark

L<Koha::Contrib::ARK> object.

=cut
has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


=attr emptyark

If true, read biblio record without ARK. If false, read biblio records with
ARK. By default, false.

=cut
has emptyark => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has sth_bn => (is => 'rw');


sub BUILD {
    my $self = shift;
    my $query =
        "SELECT biblionumber FROM biblio_metadata WHERE " .
        $self->ark->field_query .
        ($self->emptyark ? " =''" : " <> ''" );
    $self->ark->log->debug("Reader, query = $query\n");
    my $sth = C4::Context->dbh->prepare($query);
    $sth->execute;
    $self->sth_bn($sth);
}


sub read {
    my $self = shift;

    my ($biblionumber) = $self->sth_bn->fetchrow();
    return unless $biblionumber;

    my $record = GetMarcBiblio({ biblionumber => $biblionumber });
    $record = MARC::Moose::Record::new_from($record, 'Legacy');
    $self->ark->log->info("Biblio #$biblionumber\n");
    $self->ark->log->debug("ORIGINAL BIBLIO:\n", $record->as('Text')) if $record;
    return [$biblionumber, $record];
}


1;
