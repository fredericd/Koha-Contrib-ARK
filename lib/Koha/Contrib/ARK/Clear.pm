package Koha::Contrib::ARK::Clear;
# ABSTRACT: Clear Koha ARK field

use Moose;
use Modern::Perl;

with 'Koha::Contrib::ARK::Action';


sub action {
    my $self = shift;
    my $ark = $self->ark;
    my $current = $ark->current;
    my $biblio = $current->{biblio};
    my $record = $biblio->{record};

    return unless $record;

    my $ka = $ark->c->{ark}->{koha}->{ark};
    my ($tag, $letter) = ($ka->{tag}, $ka->{letter});

    my $more = $ka->{tag};
    $more .= '$' . $ka->{letter} if $ka->{letter};
    $self->ark->what_append('clear', $more);
    if ( $letter ) {
        for my $field ( $record->field($tag) ) {
            my @subf = grep {
                my $keep = $_->[0] ne $letter;
                $keep;
            } @{$field->subf};
            $field->subf( \@subf );
        }
        $record->fields( [ grep {
            $_->tag eq $tag && @{$_->subf} == 0 ? 0 : 1;
        } @{ $record->fields } ] );
    }
    else {
        $record->delete($tag);
    }

    $ark->current_modified();
}


__PACKAGE__->meta->make_immutable;
1;
