package Ansible::Module::Booleans;

use 5.020;
use utf8;

use overload (
    'qr' => '_regexify',
    '==' => '_compare',
    'eq' => '_compare',
    fallback => 0,
);

use Carp qw( croak );

sub _regexify {
    my ($self) = @_;
    use re 'eval';
    return qr/(?{Ansible::Module::Booleans::_compare($self, "$_", 0)})/;
}

sub _compare {
    my ($lhs, $rhs, $swapped) = @_;
    ($lhs, $rhs) = ($rhs, $lhs) if $swapped;
    $lhs = eval { "$lhs" } || $lhs;
    $rhs = eval { "$rhs" } || $rhs;
    return int (
        ref $rhs
        ? $lhs =~ $rhs->[ 0 ]
        : eval { "$lhs" } eq eval { "$rhs" }
    );
}

1;

package Ansible::Module::Booleans::Any;

use 5.020;
use utf8;
use base qw( Ansible::Module::Booleans );

use overload (
    'qr' => '_regexify',
    '==' => '_compare',
    'eq' => '_compare',
    fallback => 0,
);

{
    my $singleton = bless [ qr/^(y|n|yes|no|true|false|1|0)$/i ] => __PACKAGE__;
    sub new { return $singleton }
}

1;

package Ansible::Module::Booleans::True;

use 5.020;
use utf8;
use JSON::PP;
use base qw( Ansible::Module::Booleans );

use overload (
    'qr' => '_regexify',
    '==' => '_compare',
    'eq' => '_compare',
    '""' => 'stringify',
    'bool' => 'stringify',
    fallback => 0,
);

sub stringify {
    return int(1 == 1);
}

{
    my $singleton = bless [ qr/^(y|yes|true|1)$/i ] => __PACKAGE__;
    sub new { return $singleton }
}

sub TO_JSON {
    return JSON::PP::true;
}

1;

package Ansible::Module::Booleans::False;

use 5.020;
use utf8;
use JSON::PP;
use base qw( Ansible::Module::Booleans );

use overload (
    'qr' => '_regexify',
    '==' => '_compare',
    'eq' => '_compare',
    '""' => 'stringify',
    'bool' => 'stringify',
    fallback => 0,
);

sub stringify {
    return int(1 == 0);
}

{
    my $singleton = bless [ qr/^(n|no|false|0)$/i ] => __PACKAGE__;
    sub new { return $singleton }
}

sub TO_JSON {
    return JSON::PP::false;
}

1;

=head1 NAME

package Ansible::Module::Booleans - handle booleans.

=cut
