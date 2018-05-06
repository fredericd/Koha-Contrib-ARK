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
    my ($self, $record) = @_;

    my $a = $self->ark->c->{ark};
    my $ark = $a->{ARK};
    for my $var ( qw/ NMHA NAAN / ) {
        my $value = $a->{$var};
        $ark =~ s/{$var}/$value/;
    }
    my $kfield = $a->{koha}->{id};
    my $id = $record->field($kfield->{tag});
    if ( $id ) {
        $id = $kfield->{letter}
            ? $id->subfield($kfield->{letter})
            : $id->value;
    }
    if ($id ) {
        $ark =~ s/{id}/$id/;
        $kfield = $a->{koha}->{ark};
        if ( $kfield->{letter} ) {
            for my $field ( $record->field($kfield->{tag}) ) {
                my @subf = grep { $_->[0] ne $kfield->{letter}; } @{$field->subf};
                $field->subf( \@subf );
            }
            $record->fields( [ grep {
                $_->tag eq $kfield->{tag} && @{$_->subf} == 0 ? 0 : 1;
            } @{ $record->fields } ] );
        }
        else {
            $record->delete($kfield->{tag});
            $record->append( MARC::Moose::Field::Control->new(
                tag => $kfield->{tag},
                value => $ark ) );
        }
    }
    else {
        $self->ark->log->warning("This biblio record has no ID field\n")
    }

    return $record;
}


__PACKAGE__->meta->make_immutable;
1;
