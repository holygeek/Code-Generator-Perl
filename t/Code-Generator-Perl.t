use Test::More tests => 28;
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

$package_name = 'Fibonacci';#{:
ok($generator
	->new_package($package_name)
	->add_comment('Single digit fibonacci numbers')
	->add('sequence' => \@fib_sequence)
	->create(), "Generate $package_name");
use_ok($package_name);

# is_deeply is enough testing but we want to avoid the "is used only once"
# warning hence the length test:
ok(scalar @fib_sequence == scalar @{$Fibonacci::sequence},
	'Same lengths of Fibonacci sequences');
is_deeply(\@fib_sequence, $Fibonacci::sequence,
	'Fibonacci sequence matches');
#:}

$package_name = 'Number::Single::Digit';#{:
my @single_digit_numbers = ( 1..9 );
ok($generator
	->new_package($package_name)
	->add(single_digits => \@single_digit_numbers)
	->create(),
	"Generate $package_name");

use_ok($package_name);
ok(scalar @single_digit_numbers
    == scalar @{$Number::Single::Digit::single_digits},
	'Same lengths of single digit numbers');
is_deeply(\@single_digit_numbers, $Number::Single::Digit::single_digits,
		'Single digit numbers matches');
#:}

$package_name = 'Broken';#{:
SKIP: {
    eval { require Test::Output };
    skip "Need Test::Output", 1 if $@;

    $expected = <<'EOF';
Bareword found where operator expected at t/tmp/Broken.pm line 9, near "$broken var"
	(Missing operator before var?)
Error while generating t/tmp/Broken.pm:
	syntax error at t/tmp/Broken.pm line 9, near "$broken var name "
Compilation failed in require at (eval 29) line 2.
BEGIN failed--compilation aborted at (eval 29) line 2.
EOF
    Test::Output::stderr_is (sub {
	$generator
	    ->new_package($package_name)
	    ->add('broken var name' => 42)
	    ->create();
    }, $expected, 'Barf on error');
}
#:}

my $wheel_count_for = { car => 4, bicycle => 2, };

$package_name = 'CorrectOrdering';#{:
ok($generator
	->new_package($package_name)
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
#:}

$package_name = 'UseNone';#{:
ok($generator
	->new_package(
		$package_name,
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
#:}

$package_name = 'NewGeneratedBy';#{:
ok($generator
	->new_package(
		$package_name,
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
ok (compare_with_file($expected, "t/tmp/$package_name.pm"),
	"Generate $package_name");
#:}

$package_name = 'PackageReadonly';#{:
ok($generator
	->new_package(
		$package_name,
		readonly => 1)
	->add(wheel_count_for => $wheel_count_for, { sortkeys => 1, })
	->add(pi => 3.14)
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

Readonly::Scalar our \$pi => '3.14';

1;
EOT
ok (compare_with_file($expected, "t/tmp/$package_name.pm"),
	"Generate $package_name");
#:}

$package_name = 'PackageNoReadonly';#{:
ok($generator
	->new_package($package_name)
	->add(wheel_count_for => $wheel_count_for, { sortkeys => 1, })
	->add(pi => 3.14)
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

our \$pi = '3.14';

1;
EOT
ok (compare_with_file($expected, "t/tmp/$package_name.pm"),
	"Generate $package_name");
#:}

$package_name = 'VariableReadonly';#{:
ok($generator
	->new_package($package_name)
	->add_comment('This should be readonly')
	->add(wheel_count_for => $wheel_count_for, {
		sortkeys => 1,
		readonly => 1,
	      }
	  )
	->add_comment('This should not be readonly')
	->add(pi => 3.14)
	->create(),
	"Generate $package_name");
$expected = <<EOT;
package $package_name;

use strict;
use warnings;
use Readonly;

# You should never edit this file. Everything in here is automatically
# generated by t/Code-Generator-Perl.t.

# This should be readonly
Readonly::Scalar our \$wheel_count_for => {
  'bicycle' => 2,
  'car' => 4
};

# This should not be readonly
our \$pi = '3.14';

1;
EOT
ok (compare_with_file($expected, "t/tmp/$package_name.pm"),
	"Generate $package_name");
#:}

$package_name = 'VariableOverrideGlobalReadonly';#{:
$generator = new Code::Generator::Perl(readonly => 1, outdir => 't/tmp');
ok($generator
	->new_package($package_name)
	->add_comment('This should be readonly')
	->add(ten => 10)
	->add_comment('This should not be readonly')
	->add(twenty => 20, { readonly => 0 })
	->create(),
	"Generate $package_name");
$expected = <<EOT;
package $package_name;

use strict;
use warnings;
use Readonly;

# You should never edit this file. Everything in here is automatically
# generated by a script.

# This should be readonly
Readonly::Scalar our \$ten => 10;

# This should not be readonly
our \$twenty = 20;

1;
EOT
ok (compare_with_file($expected, "t/tmp/$package_name.pm"),
	"Generate $package_name");
#:}

$package_name = 'PackageOverrideGlobalReadonly';#{:
$generator = new Code::Generator::Perl(readonly => 1, outdir => 't/tmp');
ok($generator
	->new_package($package_name, readonly => 0)
	->add_comment('This should not be readonly')
	->add(ten => 10)
	->add_comment('This should not be readonly')
	->add(twenty => 20)
	->create(),
	"Generate $package_name");
$expected = <<EOT;
package $package_name;

use strict;
use warnings;
use Readonly;

# You should never edit this file. Everything in here is automatically
# generated by a script.

# This should not be readonly
our \$ten = 10;

# This should not be readonly
our \$twenty = 20;

1;
EOT
ok (compare_with_file($expected, "t/tmp/$package_name.pm"),
	"Generate $package_name");
#:}

$package_name = 'CreateVerbose'; #{:
my $message = `perl -Mblib -MCode::Generator::Perl -e '
new Code::Generator::Perl(outdir => "t/tmp")
  ->new_package("$package_name")
  ->add(pi => 3.14)
  ->create( { verbose => 1 } );
'`;
chomp $message;
ok ($message eq "t/tmp/$package_name.pm", "$package_name");
#:}

$package_name = 'CreateOrDieVerbose'; #{:
$message = `perl -Mblib -MCode::Generator::Perl -e '
new Code::Generator::Perl(outdir => "t/tmp")
  ->new_package("$package_name")
  ->add(pi => 3.14)
  ->create_or_die( "die message", { verbose => 1 } );
'`;
chomp $message;
ok ($message eq "t/tmp/$package_name.pm", "$package_name");
#:}

# vim:fdm=marker foldmarker={\:,\:}:
