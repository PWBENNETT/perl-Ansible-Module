package Ansible::Module::Utils;

use 5.020;
use utf8;

use Carp qw( croak );
use Exporter qw( import );
use JSON::PP;

use Ansible::Module::Booleans;

our @EXPORT = qw( BOOLEANS True False );

our $json = JSON::PP->new();
our $errstr;

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
    undef $errstr;
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
    my %opthash
        = eval { %{$json->decode(join ' ', @ARGV)} }
        || (map { (split /=/, $_, 2) } @ARGV)
        ;
    my %rv;
    my @errors;
    my @spurious;
    my @duplicate;
    while (my ($k, $v) = each %opthash) {
        unless (exists $args_ref->{ $k } || exists $alias{ $k }) {
            push @spurious, $k;
            next;
        }
        $k = $alias{ $k } if exists $alias{ $k };
        if (exists $rv{ $k }) {
            push @duplicate, $k;
            next;
        }
        my $valid = !scalar @{$choices{ $k }};
        for my $validator (@{$choices{ $k }}) {
            if (ref $validator eq 'CODE') {
                $valid ||= $validator->($v) and last;
            }
            elsif (ref $validator eq 'Regexp') {
                $valid ||= $v =~ $validator and last;
            }
            elsif ($v eq $validator) {
                $valid = 1;
                last;
            }
        }
        if (!$valid) {
            if (!exists $rv{ $k }) {
                push @errors, "Invalid '$k' ($v)";
                delete $required{ $k };
            }
            next;
        }
        $rv{ $k } = $v;
        delete $required{ $k };
    }
    push @errors, ("Multiple values for " . join(', ', map { "'$_'" } sort @duplicate)) if @duplicate;
    push @errors, ("Unexpected " . join(', ', map { "'$_'" } sort @spurious)) if @spurious;
    for my $k (keys %default) {
        $rv{ $k } //= $default{ $k };
        delete $required{ $k };
    }
    my @missing = keys %required;
    push @errors, ("Missing " . join(', ', map { "'$_'" } sort @missing)) if @missing;
    if (@errors) {
        $errstr = join "\n", @errors;
        return { };
    }
    return \%rv;
}

1;
