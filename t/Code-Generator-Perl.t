use Test::More qw/no_plan/;
use strict;
use warnings;

my $outdir;
BEGIN {
    use_ok('Code::Generator::Perl');
    $outdir = 't/tmp';
};

use lib $outdir;

my $generator = new Code::Generator::Perl(
			outdir => $outdir,
			generated_by => 't/Code-Generator-Perl.t',
);

my @fib_sequence = ( 1, 1, 2, 3, 5, 8 );

$generator->new_package(package => 'Fibonacci');
$generator->add_comment('Single digit fibonacci numbers');
$generator->add('sequence' => \@fib_sequence);
ok($generator->create(), 'Generate toplevel module');

use_ok('Fibonacci');

# is_deeply is enough testing but we want to avoid the "is used only once"
# warning hence the length test:
ok(scalar @fib_sequence == scalar @{$Fibonacci::sequence},
	'Same lengths of Fibonacci sequences');
is_deeply(\@fib_sequence, $Fibonacci::sequence, 'Fibonacci sequence matches');

my @single_digit_numbers = ( 1..9 );
$generator->new_package(package => 'Number::Single::Digit');
$generator->add(single_digits => \@single_digit_numbers);
ok($generator->create(), 'Generate nested module');

use_ok('Number::Single::Digit');
ok(scalar @single_digit_numbers == scalar @{$Number::Single::Digit::single_digits},
	'Same lengths of single digit numbers');
is_deeply(\@single_digit_numbers, $Number::Single::Digit::single_digits,
		'Single digit numbers matches');

$generator->new_package(package => 'Broken');
$generator->add('broken var name' => 42);
diag('You can safely ignore the following error message:');
ok(!$generator->create(), 'Barf on error');
diag('You can now go back to not-ignoring any error messages from here onwards.');