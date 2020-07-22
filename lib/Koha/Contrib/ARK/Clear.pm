package Koha::Contrib::ARK::Clear;
# ABSTRACT: Clear Koha ARK field

use Moose;
use Modern::Perl;

with 'Koha::Contrib::ARK::Action';


sub action {
    my ($self, $biblionumber, $record) = @_;

    return unless $record;

    my $ark = $self->ark;
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
}


__PACKAGE__->meta->make_immutable;
1;
