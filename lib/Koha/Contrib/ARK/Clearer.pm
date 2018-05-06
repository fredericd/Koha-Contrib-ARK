package Koha::Contrib::ARK::Clearer;
# ABSTRACT: Clear Koha ARK field
use Moose;

with 'AnyEvent::Processor::Converter';

use Modern::Perl;
use Koha::Contrib::ARK::Reader;
use Koha::Contrib::ARK::Writer;
use AnyEvent::Processor::Conversion;

=attr ark

L<Koha::Contrib::ARK> object

=cut
has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


sub convert {
    my ($self, $record) = @_;

    my $ark = $self->ark;
    my $ka = $ark->c->{ark}->{koha}->{ark};
    my ($tag, $letter) = ($ka->{tag}, $ka->{letter});

    $ark->log->debug("Remove ARK field\n");
    if ( $letter ) {
        for my $field ( $record->field($tag) ) {
            my @subf = grep { $_->[0] ne $letter; } @{$field->subf};
            $field->subf( \@subf );
        }
        $record->fields( [ grep {
            $_->tag eq $tag && @{$_->subf} == 0 ? 0 : 1;
        } @{ $record->fields } ] );
    }
    else {
        $record->delete($tag);
    }
    return $record;
}


__PACKAGE__->meta->make_immutable;
1;
