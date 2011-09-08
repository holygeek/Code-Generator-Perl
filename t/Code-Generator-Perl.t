use Test::More qw/no_plan/;
use strict;
use warnings;
my $outdir;
BEGIN {
    use_ok('Code::Generator::Perl');
    $outdir = 't/tmp';
};
use lib $outdir;

my $expected;
my $package_name;

sub compare_with_file {
    my ($expected, $filename) = @_;

    my $file_content;
    local $/;
    open my $output, '<', $filename or die $!;
    $file_content = <$output>;
    close $output;

    return $expected eq $file_content;
}


my $generator = new Code::Generator::Perl(
			outdir => $outdir,
			generated_by => 't/Code-Generator-Perl.t',
);

my @fib_sequence = ( 1, 1, 2, 3, 5, 8 );

$package_name = 'Fibonacci';
ok($generator
	->new_package(package => $package_name)
	->add_comment('Single digit fibonacci numbers')
	->add('sequence' => \@fib_sequence)
	->create(), 'Generate toplevel module');
use_ok($package_name);

# is_deeply is enough testing but we want to avoid the "is used only once"
# warning hence the length test:
ok(scalar @fib_sequence == scalar @{$Fibonacci::sequence},
	'Same lengths of Fibonacci sequences');
is_deeply(\@fib_sequence, $Fibonacci::sequence, 'Fibonacci sequence matches');

my @single_digit_numbers = ( 1..9 );
ok($generator
	->new_package(package => 'Number::Single::Digit')
	->add(single_digits => \@single_digit_numbers)
	->create(),
	'Generate nested module');

use_ok('Number::Single::Digit');
ok(scalar @single_digit_numbers == scalar @{$Number::Single::Digit::single_digits},
	'Same lengths of single digit numbers');
is_deeply(\@single_digit_numbers, $Number::Single::Digit::single_digits,
		'Single digit numbers matches');

diag('You can safely ignore the following error message:');
ok(!$generator
	->new_package(package => 'Broken')
	->add('broken var name' => 42)
	->create(),
	'Barf on error');
diag('You can now go back to not-ignoring any error messages from here onwards.');

my $wheel_count_for = { car => 4, bicycle => 2, };

$package_name = 'CorrectOrdering';
ok($generator
	->new_package(package => $package_name)
	->add(wheel_count_for => $wheel_count_for, { sortkeys => 1, })
	->create(),
	"Generate $package_name.pm");
$expected = <<EOT;
package $package_name;

use strict;
use warnings;

# You should never edit this file. Everything in here is automatically
# generated by t/Code-Generator-Perl.t.

our \$wheel_count_for = {
  'bicycle' => 2,
  'car' => 4
};

1;
EOT
ok (compare_with_file($expected, "t/tmp/$package_name.pm"), 'Correct ordering');

$package_name = 'UseNone';
ok($generator
	->new_package(
		package => $package_name,
		use => [],
		nostrict => 1,
		nowarnings => 1)
	->add(wheel_count_for => $wheel_count_for, { sortkeys => 1, })
	->create(),
	"Generate $package_name.pm");
$expected = <<EOT;
package $package_name;

# You should never edit this file. Everything in here is automatically
# generated by t/Code-Generator-Perl.t.

our \$wheel_count_for = {
  'bicycle' => 2,
  'car' => 4
};

1;
EOT
ok (compare_with_file($expected, "t/tmp/$package_name.pm"), 'Use none');

$package_name = 'NewGeneratedBy';
ok($generator
	->new_package(
		package => $package_name,
		generated_by => 'space aliens')
	->add(wheel_count_for => $wheel_count_for, { sortkeys => 1, })
	->create(),
	"Generate $package_name");
$expected = <<EOT;
package $package_name;

use strict;
use warnings;

# You should never edit this file. Everything in here is automatically
# generated by space aliens.

our \$wheel_count_for = {
  'bicycle' => 2,
  'car' => 4
};

1;
EOT
ok (compare_with_file($expected, "t/tmp/$package_name.pm"), "Generate $package_name");

$package_name = 'PackageReadonly';
ok($generator
	->new_package(
		package => $package_name,
		readonly => 1)
	->add(wheel_count_for => $wheel_count_for, { sortkeys => 1, })
	->create(),
	"Generate $package_name");
$expected = <<EOT;
package $package_name;

use strict;
use warnings;
use Readonly;

# You should never edit this file. Everything in here is automatically
# generated by t/Code-Generator-Perl.t.

Readonly::Scalar our \$wheel_count_for => {
  'bicycle' => 2,
  'car' => 4
};

1;
EOT
ok (compare_with_file($expected, "t/tmp/$package_name.pm"), "Generate $package_name");

$package_name = 'PackageNoReadonly';
ok($generator
	->new_package(package => $package_name)
	->add(wheel_count_for => $wheel_count_for, { sortkeys => 1, })
	->create(),
	"Generate $package_name");
$expected = <<EOT;
package $package_name;

use strict;
use warnings;

# You should never edit this file. Everything in here is automatically
# generated by t/Code-Generator-Perl.t.

our \$wheel_count_for = {
  'bicycle' => 2,
  'car' => 4
};

1;
EOT
ok (compare_with_file($expected, "t/tmp/$package_name.pm"), "Generate $package_name");
