package Ansible::Module::Utils;

use 5.020;
use utf8;

use Exporter qw( import );

our @EXPORT = qw( BOOLEANS True False );

sub BOOLEANS ();
sub True ();
sub False ();

sub BOOLEANS () {
    return Ansible::Module::Booleans::Any->new();
}

sub True () {
    return Ansible::Module::Booleans::True->new();
}

sub False () {
    return Ansible::Module::Booleans::False->new();
}

1;
