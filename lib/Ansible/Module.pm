package Ansible::Module;

use 5.020;
use utf8;

use Digest::SHA1 qw( sha1 );
use Exporter qw( import );
use IO::All;
use JSON::PP;
use POSIX;

use Ansible::Module::Utils;

our @EXPORT = qw( BOOLEANS True False );

our $VERSION = '0.001';
our $json = JSON::PP->new();

sub _finish ($$);

sub _finish ($$) {
    my ($exit_code, $args_ref) = @_;
    say $json->encode($args_ref);
    exit $exit_code;
}

sub new {
    my $class = ref($_[0]) ? ref(shift(@_)) : shift(@_);
    my $args_ref = (@_ % 2) ? shift(@_) : { @_ };
    my $opt_ref = Ansible::Module::Utils->getopt($args_ref->{ argument_spec });
    my $self = bless { %$args_ref, %$opt_ref } => $class;
    $self->_fail_json({ msg => $Ansible::Module::Utils::errstr }) if $Ansible::Module::Utils::errstr;
    return $self;
}

sub _exit_json {
    my $self = shift;
    my $args_ref = (@_ % 2) ? shift(@_) : { @_ };
    if (!exists $args_ref->{ changed }) {
        $args_ref->{ changed } = True;
    }
    _finish 0, $args_ref;
}

sub _fail_json {
    my $self = shift;
    my $args_ref = (@_ % 2) ? shift(@_) : { @_ };
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

    package MyModule;
    use base qw( Ansible::Module );

    my $module = MyModule->new(
        argument_spec => {
            state     => { default => 'present', choices => ['present', 'absent'] },
            name      => { required => True },
            enabled   => { required => True, choices => BOOLEANS },
            something => { aliases => ['whatever'] },
        },
        supports_check_mode => True,
    );

    if ($module->check_mode) {
        $module->exit_json(changed => $module->state_would_change);
    }

=head1 DESCRIPTION

The goal of the Ansible::Module distribution is to replicate Ansible's built-in
Python ansible_Module() support in Perl, as fully and as compatibly as possible.

Ansible Module implementations that use this module will be compatible with both
v1.x (key/value pairs in @ARGV) and v2.x (JSON in @ARGV) Ansible call APIs.

=head1 CONSTRUCTORS

=over

=item new(%OPTIONS)

Create a new Ansible::Module object.

=back

=head2 SUPPORTED new() OPTIONS

=over

=item argument_spec

Hashref defining the arguments your module implementation will accept. Each key
in the hashref is an argument name, and each value is a "Validation Hashref",
about which see below.

=back

=over

=item supports_check_mode

Ansible::Module Boolean (not a Perl boolean, see below) declaring whether or
not your module implementation supports "check" mode -- that is, whether it can
check the state of the system without changing the state of the system, or in
other words, whether it has a "pretend" mode. If you declare this to be C<True>,
then

=over

you B<MUST> check whether your implementation has been launched in check mode

if so, then you B<MUST NOT> alter the system in any palpable way

regardless, you B<MUST> (after checking whether changes would have been made)
exit setting the C<changed> flag to either

=over

C<True> - Changes are needed

C<False> - Changes are not needed

=back

=back

=back

=head2 VALIDATION HASHREFS

As noted above, each argument to your module implementation B<MUST> have an
entry in the L<argument_spec> hashref. This entry B<MUST> be a hashref and B<MUST>
conform to the following spec:

=over

B<EXACTLY ONE> of

=over

=item C<required> => C<True>

Specifies that your module implementation does B<NOT> provide a sensible default
for the argument. This may be because there are multiple possible sensible
defaults, depending on context, or because of some lazier reason.

=item C<default> => $some_value

Specifies that your module implementation B<DOES> provide a sensible default
for the argument, and what that value is.

=back

While it might be Perlish to assume an argument is required if there is not a
default value for it, the C<argument_spec> is used to auto-generate the docs
for your module implementation.

B<ZERO OR MORE> of

=over

=item aliases => \@other_names

Alternative names you're willing to accept for this argument.

=item choices => \@validators

Each validator may be a CODE ref or a Regexp ref (that is, the result of qr//
rather than a bare Regexp). Technically speaking, each validator B<MUST> provide
B<EXACTLY ONE> of "->()" or "=~" functionality, potentially via overload.

A CODE ref validator is passed the Ansible::Module object and the value to be
validated as C<$_[0]> and C<$_[1]> respectively, and should return a Perl
boolean indicating whether C<$_[1]> is valid. Altering C<$_[1]> is (as always)
possible, but inadvisable, not to mention downright impolite.

A Regexp ref validator (or anything else that overloads "=~") B<MUST> either match
or fail to match the value. At the current time, no use is made of C<$^R> for
more subtle Regexp validation functionality, though tentative plans to do so
(as well as to support politely changing C<$_[1]> in CODE ref validators) are in
place.

=back

=back

=head1 OVERLOADED BOOLEAN CONSTANTS

B<aka When is a truth not a truth?>

This module provides the special constants C<True>, C<False>, and C<BOOLEANS>.

=over

C<True> and C<False> can be supplied as return values, but they may also be
used with C<==>, C<eq>, and C<=~> to check the values of incoming data as being
"truthy" or "falsey" respectively, following rather more Pythonesque rules than
Perl's:

=over

"y", "yes", "true" (all case-insensitive), and 1 are the only truthy values, and

=back

=over

"n", "no", "false" (all case-insensitive), and 0 are the only falsy values.

=back

Other Perl "false" values such as undef or the empty string will not register
as "falsey". Other Perl "true" values (including the infamous zero-but-true
"0e0") will not register as "truthy". Because of this, you are B<strongly
urged> to pass around C<True> and C<False> instead of relying on the code to DWIM.

=back

C<BOOLEANS> is similar, except it overloads C<==>, C<eq>, and C<=~> to check
whether the supplied value matches C<True> || C<False>. It is mainly intended
to be used within the definition of argument specs.

=head1 PerlIO::via::Ansible

Do B<NOT> C<print()>, C<warn()>, C<carp()>, C<say()> or in other any way write
directly to STDOUT or STDERR from inside your module. You'll lose API compatability,
as the API writes back to the caller in pure JSON to STDOUT.

If you absolutely, positively must write raw unstructured data to your caller,
or if you want to capture the output of some module or command that insists on
logging to STDOUT or STDERR (and pass that through unaltered to your caller, you
are B<strongly encouraged> to use the bundled write-only PerlIO::via::Ansible IO
layer (see L<open> and L<perliol> for more details).

    # Oh, my! We need to call something that uses a standard Perl warn()
    open my $olderr, '>&', *STDERR;
    open my $fh, '>:via(Ansible)', 'keyname';
    open STDERR, '>&', $fh;
    warn "Why would someone do this to themselves?";
    open STDERR, '>&', $olderr;

This results in an additional key-value pair being added to the output JSON, e.g.

    {
        ...
        "keyname": "Why would somone do this to themselves? at line 123"
        ...
    }

One exception to the "don't touch STDOUT/STDERR" rule is that calls to C<die()>
are automatically piped through the above process and end up in the
{ "error": ... } key-value of the returned JSON.

=head1 LICENSE

May be redistributed and/or modified under terms of the Artistic License v2.0.

=head1 AUTHOR

PWBENNETT -- paul(dot)w(dot)bennett(at)gmail.com

=cut

