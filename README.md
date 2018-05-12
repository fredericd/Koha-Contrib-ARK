# NAME

koha-ark - Manage ARK identifiers in a Koha Catalog

# VERSION

version 1.0.3

# DESCRIPTION

Process biblio records from a Koha Catalog in order to update its ARK
identifiers. See [The ARK Identifier
Scheme](https://tools.ietf.org/id/draft-kunze-ark-15.txt). The processing is
driven by ARK\_CONF Koha system preference. It's a json variable. For example:

```perl
{
  "ark": {
    "NMHA": "myspecial.institution.fr",
    "NAAN": "12345",
    "ARK": "http://{NMHA}/ark:/{NAAN}/catalog{id}",
    "koha": {
      "id": { "tag": "099", "letter": "a" },
      "ark": { "tag": "003" }
    }
  }
}
```

ARK\_CONF system preference must contains several elements:

- **NMHA** — Name Mapping Authority Hostport. Usually it's a hostname, the
hostname of the Koha system itself, or the hostname of a proxy server (or link
resolver).
- **NAAN** — Name Assigning Authority Number. It's a number identifying the
institution, ie the Library using Koha. This number is provided for example by
the California Digital Library (CDL),
- **ARK** — It's a template used to build the ARK. Three placeholders can be used
in the template: `NMHA` and `NAAN` from ARK\_CONF, and `id` (Koha
biblio record unique identifier extracted from koha.id field).
- **koha.id** — The biblio record field which contains Koha unique id
(biblionumber or another id). Contains 2 variables: `tag` and `letter`, si it
could be a control or a standard field. For example, `{"tag": "001"}` or
`{"tag": "099", "letter": "a"}`.
- **koha.ark** — The biblio record field used to store the ARK. It could be a
control or standard field. That's this field in which this script will store
the generated field. This is also the field that this script can clear
entirely.

There are three commands: check, clear, and update

## check

Process all biblio records, and check them for: bad ARK, correct ARK in the
wrong field.

## clear

`koha-ark clear` clears the ARK field (`koha.ark` variable) in all biblio
records of the Catalog.

## update

`koha-ark update` processes all biblio that have an empty ARK field. The ARK
field is created with the appropriate ARK identifier. The ARK is build based on
`ARK` variable from ARK\_CONF. For the above ARK\_CONF, the biblio record that has
`9877` biblionumber will have this in 003 field:

```perl
http://myspecial.institution.fr/ark:/12345/biblio9877
```

# USAGE

- koha-ark check|clear|update \[--doit\] \[--verbose\] \[--debug\] \[--help\]

# SYNOPSYS

```
koha-ark clear --doit
koha-ark update --noverbose --doit
koha-ark update --debug
koha-ark check
```

# PARAMETERS

- **--doit**

    Without this parameter biblio records are not modified in Koha Catalog.

- **--verbose**

    Enable script verbose mode. Verbose by default. --noverbose disable verbosity.
    In verbose mode, a progress bar is displayed.

- **--debug**

    Info about processing is sent to a file named 'koha-ark.json' in the current
    directory. In 'debug' mode, more information is produced.

- **--help|-h**

    Print this help page.

# RESULT

The result of this script is a JSON file `koha-ark.log` which reports what has
been done.

For exemple, if ARK\_CONF is missing, the file will report the issue:

```
{
  "action" : "check"
  "timestamp" : "\"2018-05-11 16:02:15\"",
  "error" : {
     "err_pref_missing" : {
        "msg" : "ARK_CONF preference is missing",
        "id" : "err_pref_missing"
     }
  },
}
```

`koha-ark clear` contains something like this:

```
{
  "timestamp" : "2018-05-11 17:18:42",
  "action" : "clear",
  "result" : {
     "count" : "1569",
     "records" : [
        {
           "biblionumber" : "1",
           "what" : {
              "clear" : {
                 "id" : "clear",
                 "msg" : "Clear ARK field"
              }
           }
        },
        ...
  }
}
```

`koha-ark update --debug` contains something like this:

```perl
{
  "timestamp" : "2018-05-11 17:21:02",
  "action" : "update",
  "testmode": 1,
  "result" : {
     "count" : "145282",
     "records" : [
        {         
           "biblionumber" : "1570",
           "what" : {
              "generated" : {
                 "id" : "generated"
                 "msg" : "ARK generated",
                 "more" : "http://myspecial.institution.fr/ark:/12345/catalog1573",
              },
              "add" : {
                 "id" : "add",
                 "msg" : "Add ARK field"
              }
           },
           "record": [ ... ],
           "after": [ ... ]
        },
        ...
     ]
  }
}
```

# AUTHOR

Frédéric Demians &lt;f.demians@tamil.fr>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Fréderic Demians.

This is free software, licensed under:

```
The GNU General Public License, Version 3, June 2007
```
