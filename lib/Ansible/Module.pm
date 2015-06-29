package Ansible::Module;

use 5.020;
use utf8;

use Digest::SHA1 qw( sha1 );
use IO::All;
use POSIX;

use Ansible::Module::JSON;
use Ansible::Module::Utils;

our $VERSION = '0.001';

sub _finish ($$);

sub import {
    say $json->encode(\@_);
}

sub _finish ($$) {
    my ($exit_code, $args_ref) = @_;
    say $json->encode($args_ref);
    exit $exit_code;
}

sub new {
    my $class = ref($_[0]) ? ref(shift(@_)) : shift(@_);
    my ($args_ref) = @_;
    my $opt_ref = Ansible::Module::Utils->getopt($args_ref->{ argument_spec });
    my $self = bless { %$args_ref, %$opt_ref } => $class;
    $self->fail_json({ msg => $Ansible::Module::Utils::errstr }) if $Ansible::Module::Utils::errstr;
    return $self;
}

sub exit_json {
    my $self = shift;
    my ($args_ref) = @_;
    if (!exists $args_ref->{ changed }) {
        $args_ref->{ changed } = True;
    }
    _finish 0, $args_ref;
}

sub fail_json {
    my $self = shift;
    my ($args_ref) = @_;
    my $rv
        = exists($args_ref->{ errno })
        ? $args_ref->{ errno } =~ /^-?\d+$/
            ? $args_ref->{ errno }
            : eval("POSIX::" . $args_ref->{ errno })
        : 1
        ;
    if (!exists $args_ref->{ failed }) {
        $args_ref->{ failed } = True;
    }
    if (!exists $args_ref->{ msg }) {
        $args_ref->{ msg } = "Failed!";
    }
    _finish $rv, $args_ref;
}

sub sha1 {
    my $self = shift;
    my ($path) = @_;
    my $io = io($path);
    my $digest = sha1($io->slurp() . '');
    return $digest;
}

1;

__END__

=head1 NAME

Ansible::Module - Ansible Module compatible API for Perl

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

    # In your MyAnsibleModule.pm
    use Ansible::Module;
    my $module = Ansible::Module->new(
        argument_spec => {
            state     => { default='present', choices=['present', 'absent'] },
            name      => { required=True },
            enabled   => { required=True, choices=BOOLEANS },
            something => { aliases=['whatever'] },
        },
        supports_check_mode => True,
    );

    if ($module->{ check_mode }) {
        $module->exit_json(changed => check_if_system_state_would_be_changed()),
    }

=head1 DANGER

Do B<NOT> C<print> or C<say> from inside your module. You'll lose API
compatability, as the API writes back to the caller in pue JSON.

=head1 DESCRIPTION

The goal of the Ansible::Module distribution is to replicate Ansible's built-in
Python ansibleModule() support in Perl, as fully and as compatibly as possible.

=head1 CONSTRUCTORS

=head2 new

Create a new Net::IPAddress::Util object

=head1 MAGIC

This module exports special the constants C<True>, C<False>, and C<BOOLEANS>.

=over

C<True> and C<False> can be supplied as return values, but they may also be
used with C<==>, C<eq>, and C<=~> to check the values of incoming data as being
"truthy" or "falsey" respectively, following rather more Pythonesque rules than
Perl's: "y", "yes", "true", and 1 are the only truthy values, and "n", "no",
"false", and 0 are the only falsy values. Other Perl "false" values such as undef
or the empty string will not register as "falsey". Other Perl "true" values
(including the infamous zero-but-true "0e0") will not register as "truthy".

=back

=over

C<BOOLEANS> is similar, except it overloads C<==>, C<eq>, and C<=~> to check
whether the supplied value matches C<True> || C<False>. It is mainly intended
to be used within the definition of argument specs.

=back

=head1 OBJECT METHODS

=head2 is_ipv4

Returns true if this object represents an IPv4 address.

=head2 ipv4

Returns the dotted-quad representation of this object, or an error if it is
not an IPv4 address, for instance '192.168.0.1'.

=head2 as_n32

Returns the "N32" representation of this object (that is, a 32-bit number in
network order) if this object represents an IPv4 address, or an error if it
does not.

=head2 as_n128

Returns the "N128" representation of this object (that is, a 128-bit number in
network order).

You may supply one optional argument. If this argument is true, the return
value will be a Math::BigInt object (allowing quickish and easy math involving
two such return values), otherwise (if it is false (the default)), then the N128
number will be returned as a bare string. If your platform can handle math with
unsigned 128-bit integers, or if you will not be doing math on the results,
then I strongly recommend the latter (default / false) option for performance
reasons. In the true-argument case, you're advised to stringify the Math::BigInt
math results as soon as is practical for performance reasons -- Math::BigInt is
not "CPU free".

=head2 ipv6

Returns the canonical IPv6 string representation of this object, for
instance 'fe80::1234:5678:90ab' or '::ffff:192.168.0.1'.

=head2 ipv6_expanded

Returns the IPv6 string representation of this object, without compressing
extraneous zeroes, for instance 'fe80:0000:0000:0000:0000:1234:5678:90ab'.

=head2 normal_form

Returns the value of this object as a zero-padded 32-digit hex string,
without the leading '0x', suitable (for instance) for storage in a database,
or for other purposes where easy, fast sorting is desirable, for instance
'fe8000000000000000001234567890ab'.

=head2 '""'

=head2 str

=head2 as_str

=head2 as_string

If this object is an IPv4 address, it stringifies to the result of C<ipv4>,
else it stringifies to the result of C<ipv6>.

=head1 INTERNAL FUNCTIONS

=head2 ERROR

Either confess()es or cluck()s the passed string based on the value of
$Net::IPAddress::Util::DIE_ON_ERROR, and if possible returns undef.

=head1 LICENSE

May be redistributed and/or modified under terms of the Artistic License v2.0.

=head1 AUTHOR

PWBENNETT -- paul(dot)w(dot)bennett(at)gmail.com

=cut

