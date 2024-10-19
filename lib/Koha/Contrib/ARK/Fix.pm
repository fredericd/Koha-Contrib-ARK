package Koha::Contrib::ARK::Fix;
# ABSTRACT: Fix Koha ARK field

use Moose;
use Modern::Perl;

with 'Koha::Contrib::ARK::Action';


sub action {
    my ($self, $biblionumber, $record) = @_;

    return unless $record;

    my $ark = $self->ark;
    my $ka = $ark->c->{ark}->{koha}->{ark};
    my ($tag, $letter) = ($ka->{tag}, $ka->{letter});

    # Is a bad ARK found in the correct field?
    my $ark_value = $self->ark->build_ark($biblionumber, $record);
    my $field = $record->field($tag);
    return unless $field;
    my $current_ark = $letter ? $field->subfield($letter) : $field->value;
    return if $current_ark eq $ark_value;

    my $more = "Replace \"$current_ark\" with \"$ark_value\"";
    $self->ark->what_append('fix', $more);
    $self->ark->current_modified();

    if ($letter) {
        my $done = 0;
        $field->subf( [ map {
            if (!$done && $_->[0] eq $letter) {
                $_->[1] = $ark_value;
                $done = 1;
            }
            $_;
        } @{$field->subf} ]);
    }
    else {
        $field->value($ark_value);
    }
}


__PACKAGE__->meta->make_immutable;
1;
