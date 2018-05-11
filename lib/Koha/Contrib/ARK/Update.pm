package Koha::Contrib::ARK::Update;
# ABSTRACT: Update Koha ARK fields


use Moose;

with 'Koha::Contrib::ARK::Action';

use Modern::Perl;



sub action {
    my ($self, $biblionumber, $record) = @_;

    my $a = $self->ark->c->{ark};
    my $ark = $self->ark->build_ark($biblionumber, $record);
    my $kfield = $a->{koha}->{ark};
    if ( $kfield->{letter} ) { # datafield
        if ( my $field = $record->field($kfield->{tag}) ) {
            my @subf = grep {
                my $keep = $_->[0] ne $kfield->{letter};
                $self->ark->what_append('remove_existing') unless $keep;
                $keep;
            } @{$field->subf};
            push @subf, [ $kfield->{letter} => $ark ];
            $field->subf( \@subf );
        }
        else {
            $record->append( MARC::Moose::Field::Std->new(
                tag => $kfield->{tag}, subf => [ [ $kfield->{letter} => $ark ] ] ) );
        }
    }
    else {
        if ( $record->field($kfield->{tag}) ) {
            $record->delete($kfield->{tag});
            $self->ark->what_append('remove_existing');
        }
        $record->append( MARC::Moose::Field::Control->new(
            tag => $kfield->{tag},
            value => $ark ) );
    }
    $self->ark->what_append('add');
}


__PACKAGE__->meta->make_immutable;
1;
