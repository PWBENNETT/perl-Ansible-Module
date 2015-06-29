use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Ansible::Module',
    AUTHOR              => q{Paul Bennett <paul.w.bennett@gmail.com>},
    VERSION_FROM        => 'lib/Ansible/Module.pm',
    ABSTRACT_FROM       => 'lib/Ansible/Module.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => '0',
        'Exporter' => '0',
        'JSON::PP' => '0',
        'overload' => '0',
        'utf8' => '0',
    },
    TEST_REQUIRES => { 'Test::More' => 0, },
    MIN_PERL_VERSION => '5.012000',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-IPAddress-Util-*' },
);
