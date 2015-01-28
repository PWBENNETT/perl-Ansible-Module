package Ansible::Module;

use 5.020;
use utf8;

use Ansible::Module::Utils;
use Data::Dumper;
use JSON::PP;

our $VERSION = '0.001';

our $json = JSON::PP->new();
$json->allow_unknown(1);
$json->allow_blessed(1);
$json->convert_blessed(1);

sub import {
    say Dumper \@_;
}

sub new {
    my $class = ref($_[0]) ? ref(shift(@_)) : shift(@_);
    my ($args_ref) = @_;
    my $opt_ref = Ansible::Module::Utils->getopt($args_ref);
    return bless $opt_ref => $class;
}

sub exit_json {
    my $self = shift;
    my ($args_ref) = @_;
    if (!exists $args_ref->{ changed }) {
        $args_ref->{ changed } = True;
    }
    say $json->encode($args_ref);
    exit 0;
}

sub fail_json {
    my $self = shift;
    my ($args_ref) = @_;
    if (!exists $args_ref->{ failed }) {
        $args_ref->{ failed } = True;
    }
    if (!exists $args_ref->{ msg }) {
        $args_ref->{ msg } = "Failed!";
    }
    say $json->encode($args_ref);
    exit 1;
}

1;
