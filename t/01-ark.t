use Modern::Perl;
use MARC::Moose::Record;
use MARC::Moose::Field;
use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;
use MARC::Moose::Parser::Marcxml;
use Koha::Contrib::ARK;
use YAML;
use JSON;


use Test::More tests => 16;
use Test::MockModule;
use t::Mocks;


my $xml_chunk = <<EOS;
<record>
  <leader>01529    a2200217   4500</leader>
  <controlfield tag="001">1234</controlfield>
  <controlfield tag="005">20180505165105.0</controlfield>
  <controlfield tag="008">800108s1899    ilu           000 0 eng  </controlfield>
  <controlfield tag="009">132000601</controlfield>
  <datafield tag="020" ind1=" " ind2=" ">
    <subfield code="a">0-19-877306-4</subfield>
  </datafield>
  <datafield tag="041" ind1=" " ind2=" ">
    <subfield code="a">eng</subfield>
  </datafield>
  <datafield tag="100" ind1=" " ind2=" ">
    <subfield code="a">Burda, Michael C.</subfield>
    <subfield code="u">Economics and Political Science</subfield>
  </datafield>
  <datafield tag="245" ind1=" " ind2=" ">
    <subfield code="a">Macroeconomics:</subfield>
    <subfield code="b">a European text</subfield>
  </datafield>
  <datafield tag="260" ind1=" " ind2=" ">
    <subfield code="b">Oxford University Press,</subfield>
    <subfield code="c">1993.</subfield>
  </datafield>
  <datafield tag="300" ind1=" " ind2=" ">
    <subfield code="a">486 p. :</subfield>
    <subfield code="b">Graphs ;</subfield>
    <subfield code="c">25 cm.</subfield>
  </datafield>
  <datafield tag="690" ind1=" " ind2=" ">
    <subfield code="a">Economics</subfield>
  </datafield>
  <datafield tag="700" ind1=" " ind2=" ">
    <subfield code="a">Wyplosz, Charles</subfield>
  </datafield>
  <datafield tag="942" ind1=" " ind2=" ">
    <subfield code="a">bib777</subfield>
    <subfield code="c">BK</subfield>
  </datafield>
  <datafield tag="952" ind1=" " ind2=" ">
    <subfield code="1">0</subfield>
    <subfield code="7">0</subfield>
    <subfield code="a">DO</subfield>
    <subfield code="b">DO</subfield>
    <subfield code="c">MC</subfield>
    <subfield code="o">HB172.5 .B87 1993</subfield>
    <subfield code="p">000426795</subfield>
    <subfield code="y">BK</subfield>
  </datafield>
</record>
EOS

my $ark_conf = {
    ark => {
        "NMHA" => "myspecial.test.fr",
        "NAAN" => "12345",
        "ARK" => "http://{NMHA}/ark:/{NAAN}/catalog{id}",
        "koha" => {
          "id" => { "tag" => "001" },
          "ark" => { "tag" => "090", "letter" => "z" }
        }
    }
};

my $parser = MARC::Moose::Parser::Marcxml->new();
my $record = $parser->parse( $xml_chunk );

my $ark_conf_json = to_json($ark_conf, {pretty=>1});
t::Mocks::mock_preference('ARK_CONF', $ark_conf_json);

my $ark = Koha::Contrib::ARK->new();
is( $ark->cmd, 'check', "->cmd default value is 'check'" );
is( $ark->verbose, '0', "->verbose default value is '0'" );
is( $ark->doit, '0', "->doit default value is '0'" );
is(
    $ark->field_query,
    "ExtractValue(metadata, '//datafield[\@tag=\"090\"]/subfield[\@code=\"z\"]')",
    "->field_query properly build" );
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalog1234',
    "valid ARK generated for ID 1234 by build_ark" );
$record->field('001')->value('4321');
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalog4321',
    "valid ARK generated for ID 4321 by build_ark" );
$record->delete('001');
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalog1234',
    "valid ARK generated for ID 1234 (fallback to biblionumber without 001) by build_ark" );
$record->append( MARC::Moose::Field::Control->new( tag => '001', value => '1234' ) );

# Take the ID in 009 field rather than 001
$ark_conf->{ark}->{koha}->{id} = { tag => '009' };
$ark_conf_json = to_json($ark_conf, {pretty=>1});
t::Mocks::mock_preference('ARK_CONF', $ark_conf_json);
$ark = Koha::Contrib::ARK->new();
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalog132000601',
    "valid ARK generated by build_ark - ID from 009" );
$record->delete('009');
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalog1234',
    "valid ARK generated (fallback to biblionumber without 009) by build_ark" );

# Take the ID in 942$a
$ark_conf->{ark}->{koha}->{id} = { tag => '942', letter => 'a' };
$ark_conf_json = to_json($ark_conf, {pretty=>1});
t::Mocks::mock_preference('ARK_CONF', $ark_conf_json);
$ark = Koha::Contrib::ARK->new();
is(
    $ark->build_ark(1234, $record),
    'http://myspecial.test.fr/ark:/12345/catalogbib777',
    "valid ARK generated by build_ark - ID from 942\$a" );

my $updater = Koha::Contrib::ARK::Updater->new( ark => $ark );
$updater->convert([1234, $record]);
my $ark_field = $record->field('090');
ok( $ark_field, "ARK field 090 present is the record" );
is(
    $ark_field->subfield('z'),
    "http://myspecial.test.fr/ark:/12345/catalogbib777",
    "ARK field properly populated in 090\$z" );

my $clearer = Koha::Contrib::ARK::Clearer->new( ark => $ark );
$clearer->convert([1234, $record]);
ok( !$record->field('090'), "ARK field 090 deleted" );

$ark_conf->{ark}->{koha}->{ark} = { tag => '003' };
$ark_conf_json = to_json($ark_conf, {pretty=>1});
t::Mocks::mock_preference('ARK_CONF', $ark_conf_json);
$ark = Koha::Contrib::ARK->new();
$updater = Koha::Contrib::ARK::Updater->new( ark => $ark );
$updater->convert([1234, $record]);
$ark_field = $record->field('003');
ok( $ark_field, "ARK field 003 present is the record" );
is(
    $ark_field->value,
    "http://myspecial.test.fr/ark:/12345/catalogbib777",
    "ARK field properly populated in 003" );

$clearer = Koha::Contrib::ARK::Clearer->new( ark => $ark );
$clearer->convert([1234, $record]);
ok( !$record->field('003'), "ARK field 003 deleted" );

