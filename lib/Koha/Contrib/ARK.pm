package Koha::Contrib::ARK;
# ABSTRACT: ARK Management
use Moose;


use Modern::Perl;
use JSON;
use YAML;
use C4::Context;
use C4::Biblio;
use Try::Tiny;
use Log::Dispatch;
use Log::Dispatch::Screen;
use Log::Dispatch::File;
use Koha::Contrib::ARK::Updater;
use Koha::Contrib::ARK::Clearer;



has c => ( is => 'rw', isa => 'HashRef' );

=attr doit

Is the process effective?

=cut
has doit => ( is => 'rw', isa => 'Bool', default => 0 );

=attr verbose

Operate in verbose mode

=cut
has verbose => ( is => 'rw', isa => 'Bool', default => 0 );

=attr loglevel

Logging level. The usual suspects: debug info warn error fatal.

=cut
has loglevel => (
    is => 'rw',
    isa => 'Str',
    default => 'debug',
);

has field_query => ( is => 'rw', isa => 'Str' );

has log => (
    is => 'rw',
    isa => 'Log::Dispatch',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $log = Log::Dispatch->new();
        $log->add( Log::Dispatch::File->new(
            name      => 'file1',
            min_level => $self->loglevel,
            filename  => './koha-ark.log',
            mode      => '>>',
            binmode   => ':encoding(UTF-8)',
        ) );
        return $log;
    }
);


sub fatal {
    my ($self, $msg) = @_;
    $self->log->fatal("$msg\n");
    exit;
}


sub BUILD {
    my $self = shift;

    $self->log->debug("Reading ARK_CONF\n");
    my $c = C4::Context->preference("ARK_CONF");
    $self->fatal("ARK_CONF Koha system preference is missing") unless $c;
    $self->log->debug("ARK_CONF=\n$c\n");

    try {
        $c = decode_json($c);
    } catch {
        $self->fatal("Error while decoding json ARK_CONF preference: $_");
    };

    my $a = $c->{ark};
    $self->fatal("Invalid ARK_CONF preference: 'ark' variable is missing") unless $a;

    # Check koha fields
    for my $name ( qw/ id ark / ) {
        my $field = $a->{koha}->{$name};
        $self->fatal("Missing: koha.$name") unless $field;
        $self->fatal("Missing: koha.$name.tag") unless $field->{tag};
        $self->fatal("Invalid koha.$name.tag") if $field->{tag} !~ /^[0-9]{3}$/;
        $self->fatal("Missing koha.$name.letter")
            if $field->{tag} !~ /^00[0-9]$/ && ! $field->{letter};
    }

    my $id = $a->{koha}->{ark};
    my $field_query =
        $id->{letter}
        ? '//datafield[@tag="' . $id->{tag} . '"]/subfield[@code="' .
          $id->{letter} . '"]'
        : '//controlfield[@tag="' . $id->{tag} . '"]';
    $field_query = "ExtractValue(metadata, '$field_query')";
    $self->log->debug("field_query = $field_query\n");
    $self->field_query( $field_query );

    $self->c($c);
}


sub run {
    my $self = shift;
    my %p = @_;

    $self->log->info("Process ARK in Koha Catalog: $p{name}\n\n");

    AnyEvent::Processor::Conversion->new(
        reader    => Koha::Contrib::ARK::Reader->new(
            ark => $self,
            emptyark => $p{name} eq 'update',
        ),
        writer    => Koha::Contrib::ARK::Writer->new( ark => $self ),
        converter => $p{name} eq 'update'
            ? Koha::Contrib::ARK::Updater->new( ark => $self )
            : Koha::Contrib::ARK::Clearer->new( ark => $self ),
        verbose   => $self->verbose(),
    )->run();
}


__PACKAGE__->meta->make_immutable;
1;
