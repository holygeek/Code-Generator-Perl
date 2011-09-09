use Test::More;

SKIP: {
	eval "use Test::Pod::Coverage 1.00";

	skip "Test::Pod::Coverage", 1 if $@;

	pod_coverage_ok('Code::Generator::Perl', 'Pod coverage');
}
done_testing();
