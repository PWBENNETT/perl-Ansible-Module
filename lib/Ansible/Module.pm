package Ansible::Module;

use 5.020;
use utf8;

use Ansible::Module::Utils;
use Data::Dumper;
use JSON::XS;

sub import {
    say Dumper \@_;
}

sub new {
    my $class = ref($_[0]) ? ref(shift(@_)) : shift(@_);
    my ($args_ref) = @_;
    my $opt_ref = Ansible::Module::Utils->getopt($args_ref);
    return bless $opt_ref => $class;
}

1;
