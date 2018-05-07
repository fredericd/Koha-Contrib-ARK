package Koha::Contrib::ARK::Updater;
# ABSTRACT: Update Koha ARK fields
use Moose;

with 'AnyEvent::Processor::Converter';

use Modern::Perl;
use JSON;
use YAML;
use C4::Context;
use C4::Biblio;
use Try::Tiny;

=attr ark

L<Koha::Contrib::ARK> object.

=cut
has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


sub convert {
    my ($self, $br) = @_;
    my ($biblionumber, $record) = @$br;

    my $a = $self->ark->c->{ark};
    my $ark = $self->ark->build_ark($biblionumber, $record);
    $self->ark->log->info("Generated ARK: $ark\n");
    my $kfield = $a->{koha}->{ark};
    if ( $kfield->{letter} ) { # datafield
        if ( my $field = $record->field($kfield->{tag}) ) {
            my @subf = grep { $_->[0] ne $kfield->{letter}; } @{$field->subf};
            push @subf, [ $kfield->{letter} => $ark ];
            $field->subf( \@subf );
        }
        else {
            $record->append( MARC::Moose::Field::Std->new(
                tag => $kfield->{tag}, subf => [ [ $kfield->{letter} => $ark ] ] ) );
        }
    }
    else {
        $record->delete($kfield->{tag});
        $record->append( MARC::Moose::Field::Control->new(
            tag => $kfield->{tag},
            value => $ark ) );
    }

    return [$biblionumber, $record];
}


__PACKAGE__->meta->make_immutable;
1;
