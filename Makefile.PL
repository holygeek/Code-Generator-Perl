use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Code::Generator::Perl',
    VERSION_FROM      => 'lib/Code/Generator/Perl.pm', # finds $VERSION
    PREREQ_PM         => {
	# These are the versions that happen to be in my local site perl.
	# Change these to suit your need, please report back if it works fine.
	# I'm too lazy to check the specific requirement at the moment.
	'Data::Dumper' => 2.121,
	'File::Spec'   => 3.29,
	'File::Path'   => 2.07,
    },
    META_MERGE => {
	resources => {
	    repository => 'https://github.com/holygeek/Code-Generator-Perl',
	},
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Code/Generator/Perl.pm', # retrieve abstract from module
       AUTHOR         => 'nazri <nazri@>') : ()),
    clean             => { FILES => 't/tmp' },
    LICENSE           => 'perl',
);
