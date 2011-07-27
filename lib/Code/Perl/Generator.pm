package Code::Perl::Generator;

use Data::Dumper;

our $VERSION = '0.01';

sub new {
	my ($class, %details) = @_;
	my $self = {};
	$self->{outdir} = $details{outdir} || '.';
	$self->{package} = $details{package};
	$self->{content} = ();
	bless ($self, $class);
	return $self;
}

sub new_package {
	my ($self, %details) = @_;
	$self->{outdir} = $details{outdir} || $self->{outdir};
	$self->{package} = $details{package} || warn "new_package: No package given";
	$self->{content} = ();
}

sub add_comment {
	my ($self, @comments) = @_;
	$self->_add_content("# " . join("\n# ", @comments));
}

sub hash_keys_sorter {
	my ($hash_ref) = @_;
	my @keys = keys %$hash_ref;

	# Assume all keys are numeric if one of them is
	# and sort them numerically
	if ($keys[0] =~ /^\d+$/) {
		@keys = sort { $a <=> $b } @keys;
	} else {
		@keys = sort @keys;
	}
	return \@keys;
}

sub add {
	my ($self, $name, $value, $options) = @_;
	local $Data::Dumper::Indent = 1;
	local $Data::Dumper::Purity = 1;
	my $content;
	if ($options->{sortkeys}) {
		local $Data::Dumper::Sortkeys = \&hash_keys_sorter;
		$content = Data::Dumper->Dump([$value], [$name])
	} else {
		local $Data::Dumper::Sortkeys = 0;
		$content = Data::Dumper->Dump([$value], [$name])
	}
	$self->_add_content('our ' . $content);
}

sub _add_content {
	my ($self, $content) = @_;
	push @{$self->{content}}, $content;
}

sub create {
	my ($self) = @_;

	my $outdir = $self->{outdir};
	my $package = $self->{package};
	my @dir = split('::', $self->{package});
	my $filename = pop @dir;
	$outdir = join('/', $outdir, @dir);
	$filename = join('/', $outdir, $filename . '.pm');

	if (! -d $package_dir) {
		`mkdir -p $outdir`;
	}

	open my $file, ">$filename" or die "Could not open $filename\n";
	print $file <<EOF;
package $package;

use strict;
use warnings;

# You should never edit this file

EOF
	print $file join("\n", @{$self->{content}});

	print $file "\n1;";
	close $file;
	return $self->verify_package($package, $filename);
}

sub verify_package {
	my ($self, $package, $filename) = @_;
	eval "use $package;";
	if ($@) {
		warn "Generator.pm: Syntax error in $filename
		Error: $@";
		return 0;
	} else {
		if ($ENV{verbose}) {
			print STDERR "$filename\n";
		}
	}
	return 1;
}

sub create_or_die {
	my ($self, $die_message) = shift;
	if (! $self->create()) {
		die "$die_message";
	}
}

1;
__END__
=head1 NAME

Code::Perl::Generator - Perl module for generating perl modules

=head1 SYNOPSIS

  use Code::Perl::Generator;

  my $generator = new Code::Perl::Generator();

  my @fib_sequence = ( 1, 1, 2, 3, 5, 8 );

  $generator->new_package(package => 'Fibonacci');

  $generator->add_comment('Single digit fibonacci numbers');
  $generator->add(fib_sequence => \@fib_sequence);
  # This will generate this entry in the file Fibonacci.pm:
  #
  #     my $fib_sequence = [ 1, 2, 3, 5, 8 ];

  # Generates Fibonacci.pm
  $generator->create_or_die();

  my @single_digit_numbers = ( 1..9 );
  $generator->new_package(package => 'Number::Single::Digit');
  $generator->add(single_digits => \@single_digit_numbers);

  # Generates Number/Single/Digit.pm
  $generator->create_or_die();

=head1 DESCRIPTION

Code::Perl::Generator generates perl modules for you.

The idea is that you specify the module name and what variables it has and it
will spit out the .pm files for you, using Data::Dumper to do the actual
nitty-gritty work.

It was born out of the need to generate perl modules for representing static
data relationship from relational database tables. The static data doesn't
change all that often so having them pre-calculated in some perl module
somewhere saves precious cpu time that would have been spent on doing table
joins to come up with the same data.

=head1 SEE ALSO

Data::Dumper

=head1 AUTHOR

Nazri Ramliy, E<lt>ayiehere@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Nazri Ramliy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
