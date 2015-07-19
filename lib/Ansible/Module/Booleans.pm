package Ansible::Module::Booleans;

use 5.020;
use utf8;

use overload (
    'qr' => 'regexify',
    '==' => 'compare',
    'eq' => 'compare',
    fallback => 0,
);

use Carp qw( croak );

sub regexify {
    my ($self) = @_;
    use re 'eval';
    return qr/(?{Ansible::Module::Booleans::compare($self, "$_", 0)})/;
}

sub compare {
    my ($lhs, $rhs, $swapped) = @_;
    return $rhs =~ $lhs->[ 0 ];
}

1;

package Ansible::Module::Booleans::Any;

use 5.020;
use utf8;
use base qw( Ansible::Module::Booleans );

use overload (
    'qr' => 'regexify',
    '==' => 'compare',
    'eq' => 'compare',
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
    'qr' => 'regexify',
    '==' => 'compare',
    'eq' => 'compare',
    '""' => 'stringify',
    'bool' => 'stringify',
    fallback => 0,
);

sub stringify {
    return 1 == 1;
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
    'qr' => 'regexify',
    '==' => 'compare',
    'eq' => 'compare',
    '""' => 'stringify',
    'bool' => 'stringify',
    fallback => 0,
);

sub stringify {
    return 1 == 0;
}

{
    my $singleton = bless [ qr/^(n|no|false|0)$/i ] => __PACKAGE__;
    sub new { return $singleton }
}

sub TO_JSON {
    return JSON::PP::false;
}

1;
