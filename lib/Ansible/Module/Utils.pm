package Ansible::Module::Utils;

use 5.020;
use utf8;

use Carp qw( croak );
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

sub getopt {
    shift if $_[0] eq __PACKAGE__;
    my ($args_ref) = @_;
    my %required;
    my %default;
    my %alias;
    my %choices;
    for my $k (keys %$args_ref) {
        if ($args_ref->{ $k }->{ required } =~ BOOLEANS) {
            $required{ $k } = delete $args_ref->{ $k }->{ required };
        }
        if (exists $args_ref->{ $k }->{ default }) {
            $default{ $k } = delete $args_ref->{ $k }->{ default };
            delete $required{ $k };
        }
        $args_ref->{ $k }->{ aliases } = delete $args_ref->{ $k }->{ alias } if $args_ref->{ $k }->{ alias };
        if (exists $args_ref->{ $k }->{ aliases }) {
            $args_ref->{ $k }->{ aliases } = [ $args_ref->{ $k }->{ aliases } ] unless ref $args_ref->{ $k }->{ aliases };
            for my $aka (@{$args_ref->{ $k }->{ aliases }}) {
                $alias{ $aka } = $args_ref->{ $k };
            }
            delete $args_ref->{ $k }->{ aliases };
        }
        if (exists $args_ref->{ $k }->{ choices }) {
            $args_ref->{ $k }->{ choices } = [ $args_ref->{ $k }->{ choices } ] unless ref $args_ref->{ $k }->{ choices };
            $choices{ $k } = delete $args_ref->{ $k }->{ choices };
        }
    }
    my @opts = @ARGV;
    my %rv;
    my @spurious;
    my @duplicate;
    for my $opt (@opts) {
        my ($k, $v) = split /=/, $opt, 2;
        unless (exists $args_ref->{ $k } || exists $alias{ $k }) {
            push @spurious, $k;
            next;
        }
        $k = $alias{ $k } if exists $alias{ $k };
        if (exists $rv{ $k }) {
            push @duplicate, $k;
            next;
        }
        $rv{ $k } = $v;
        delete $required{ $k };
    }
    my @errors;
    push @errors, ("Multiple values for " . join(', ', map { "'$_'" } @duplicate)) if @duplicate;
    push @errors, ("Unexpected " . join(', ', map { "'$_'" } @spurious)) if @spurious;
    for my $k (keys %default) {
        $rv{ $k } //= $default{ $k };
        delete $required{ $k };
    }
    my @missing = grep { !!$_ } keys %required;
    push @errors, ("Missing " . join(', ', map { "'$_'" } @missing)) if @missing;
    croak(join "\n", @errors) if @errors;
    return \%rv;
}

1;
