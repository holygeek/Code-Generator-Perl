package Code::Generator::Perl;

use strict;
use warnings;

use Data::Dumper;
use Carp;
use File::Spec::Functions;
use File::Path qw(make_path);

my %packages_created;

our $VERSION = '0.03';    # Don't forget to update the one in POD too!

sub new {
    my ($class, %details) = @_;

    my $self = {};
    $self->{outdir}       = $details{outdir} || '.';
    $self->{base_package} = $details{base_package};
    $self->{readonly}     = $details{readonly} || 0;
    $self->{content}      = ();
    $self->{generated_by} = $details{generated_by} || 'a script';

    bless($self, $class);
    return $self;
}

sub _init_use {
    my ($self) = @_;

    my $uses = $self->{use};
    if (defined $uses) {
        foreach my $package (@{$uses}) {
            $self->use($package);
        }
    }
    else {
        $self->use(qw/strict warnings/);
    }

    if ($self->{readonly} || $self->{package_readonly}) {
        $self->use('Readonly');
    }
}

sub use {
    my ($self, @packages) = @_;

    map { $self->_add_if_not_yet_used($_) } @packages;
    return $self;
}

sub _add_if_not_yet_used {
    my ($self, $package) = @_;

    if (!grep {/$package/} @{$self->{use}}) {
        push @{$self->{use}}, $package;
    }
}

sub new_package {
    my ($self, $package_name, %details) = @_;

    $self->{package} = $package_name
      || die "new_package: Missing package name";
    $self->{outdir} = $details{outdir} || $self->{outdir};
    $self->{use}    = $details{use}    || [];
    $self->{package_generated_by} = $details{generated_by};
    unshift @{$self->{use}}, 'warnings' if !defined $details{nowarnings};
    unshift @{$self->{use}}, 'strict'   if !defined $details{nostrict};

    if (defined $self->{base_package}) {
        $self->{package} = join('::', $self->{base_package}, $self->{package});
    }
    $self->{content} = ();

    $self->{package_readonly} = $self->{readonly};
    $self->{package_readonly} = $details{readonly}
      if defined $details{readonly};

    $self->_init_use();
    return $self;
}

sub add_comment {
    my ($self, @comments) = @_;

    $self->_add_content("# " . join("\n# ", @comments));
    return $self;
}

sub add {
    my ($self, $name, $value, $options) = @_;

    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Purity   = 1;
    local $Data::Dumper::Deepcopy = 0;
    local $Data::Dumper::Sortkeys = $options->{sortkeys} || 0;

    my $readonly = $self->{readonly};
    $readonly = $self->{package_readonly}
      if defined $self->{package_readonly};
    $readonly = $options->{readonly} if defined $options->{readonly};

    local $Data::Dumper::Deepcopy = $readonly;

    my $content = Data::Dumper->Dump([$value], [$name]);

    if ($readonly) {
        $self->use('Readonly');
        $content =~ s/=/=>/;
        $self->_add_content('Readonly::Scalar our ' . $content);
    }
    else {
        $self->_add_content('our ' . $content);
    }
    return $self;
}

sub add_verbatim {
    my ($self, $text) = @_;

    $self->_add_content($text);
    return $self;
}

sub _add_content {
    my ($self, $content) = @_;

    push @{$self->{content}}, $content;
}

sub _get_line_printer_for {
    my ($filename) = @_;

    open my $file, '>', $filename or die "Could not open $filename\n";

    return (
        sub {
            my ($str) = @_;
            $str ||= '';
            print $file "$str\n";
        },
        sub {
            close $file;
        },
    );
}

sub _create_directory_or_die {
    my ($outdir) = @_;

    make_path($outdir, {error => \my $errors});
    if (@$errors) {
        for my $diag (@$errors) {
            my ($dir, $message) = %$diag;

            # At most we're creating only one path so dying
            # immediately is all dandy here. Should be no problem
            # for immortals like us.
            die "Error creating output directory '$outdir': $message";
        }
    }
}

sub _get_outdir_and_filename {
    my ($self) = @_;

    my $outdir   = $self->{outdir};
    my @dir      = split('::', $self->{package});
    my $filename = pop @dir;

    $outdir   = catfile($outdir, @dir);
    $filename = catfile($outdir, $filename . '.pm');

    return ($outdir, $filename);
}

sub create {
    my ($self, $options) = @_;

    my $package = $self->{package};
    if ($packages_created{$package}) {
        croak join("\n",
            "ERROR: Package $package has already been written before!",
            "\tMost likely this is not what you want.",
            "\tBailing out.",
        );
    }
    $packages_created{$package} = 1;

    my ($outdir, $filename) = $self->_get_outdir_and_filename();

    if (!-d $outdir) {
        _create_directory_or_die($outdir);
    }

    my ($print_line, $done) = _get_line_printer_for($filename);
    $print_line->("package $package;");
    $print_line->();

    map { $print_line->("use $_;") } @{$self->{use}};
    $print_line->() if (scalar @{$self->{use}});

    $print_line->('# You should never edit this file. '
          . 'Everything in here is automatically');
    $print_line->('# generated by '
          . ($self->{package_generated_by} || $self->{generated_by})
          . '.');
    $print_line->();

    map { $print_line->($_) } @{$self->{content}};

    $print_line->('1;');
    $done->();
    return $self->_verify_package($package, $filename, $options);
}

sub _verify_package {
    my ($self, $package, $filename, $options) = @_;

    my $outdir = $self->{outdir};

    eval <<"	EOF";
	use lib '$outdir';
	use $package;
	EOF
    if ($@) {
        warn "Error while generating $filename:\n\t$@";
        return 0;
    }
    else {
        if ($options->{verbose}) {
            print "$filename\n";
        }
    }
    eval <<"	EOF";
	no lib '$outdir';
	no $package;
	EOF
    return 1;
}

sub create_or_die {
    my ($self, $die_message, $options) = @_;

    $die_message ||= '';
    if (!$self->create($options)) {
        die "$die_message $!";
    }
}

1;
__END__

=head1 NAME

Code::Generator::Perl - Perl module for generating perl modules

=head1 VERSION

0.03

=head1 SYNOPSIS

  use Code::Generator::Perl;

  my $generator = Code::Generator::Perl->new(generated_by => 'somescript.pl');

  my @fib_sequence = ( 1, 1, 2, 3, 5, 8 );

  $generator->new_package( 'Fibonacci' );

  $generator->add_comment( 'Single digit fibonacci numbers' );
  $generator->add( fib_sequence => \@fib_sequence );
  $generator->create_or_die();
  # This will generate the file Fibonacci.pm:
  #
  #     package Fibonacci;
  #
  #     use strict;
  #     use warnings;
  #
  #     # You should never edit this file. Everything in here is automatically
  #     # generated by somescript.pl.
  #
  #     # Single digit fibonacci numbers
  #     our $sequence = [
  #       1,
  #       1,
  #       2,
  #       3,
  #       5,
  #       8
  #     ];
  #
  #     1;

  my @single_digit_numbers = ( 1..9 );
  $generator->new_package( 'Number::Single::Digit' );
  $generator->add(single_digits => \@single_digit_numbers);

  # Generates Number/Single/Digit.pm
  $generator->create_or_die();

=head1 DESCRIPTION

Code::Generator::Perl generates perl modules for you.

The idea is that you specify the module name and what variables it has and it
will spit out the .pm files for you, using I<Data::Dumper> to do the actual
nitty-gritty work.

It was born out of the need to generate perl modules for representing static
data relationship from relational database tables. The static data doesn't
change all that often so having them pre-calculated in some perl module
somewhere saves precious cpu time that would have been spent on doing table
joins to come up with the same data.

=head2 Methods

=over 4

=item I<new>( option => value, ... )

Creates the generator object.  Available options are

=over 4

=item I<outdir>

Specifies the directory where the generated files will be saved to.

=item I<base_package>

The base package to be prepended to the package name.

=item I<readonly>

Set this to true if you would like all the variables in all the packages to be
generated to be readonly. This requires the Readonly module. You can overide
this in per-package or per-variable readonly option.

=item I<generated_by>

Set this to the name of your script so that people that view the generated file
know which script generates your generated files.

=back

=item I<new_package>( 'Package::Name', option => value, ... )

Prepare the generator for creating a new package. Previous contents are cleared.
Valid options are:

=over 4

=item I<outdir>

The output directory for this package.

=item I<use>

An array ref to a list of other modules to use. By default 'strict' and
'warnings' are included. Specify the 'nowarnings' and 'nostrict' if you don't
want them (see below).

=item I<nowarnings>

Exclude 'use warnings' if set to true.

=item I<nostrict>

Exclude 'use strict' if set to true.

=item I<package_generated_by>

Similar to 'generated_by' option to new but for this package only.

=item I<base_package>

The base package name to be prepended to this package.

=item I<package_readonly>

Set to 1 if you would like all variables in this package to be readonly.

=back

=item I<add_comment>( 'some comment', 'another comment' )

Add comments. They will be joined with newlines.

=item I<add>( variable_name => $ref, { option => value } )

Add a variable with the given name, pointing to $ref. Options are:

=over 4

=item I<sortkeys>

This value will be passed to I<$Data::Dumper::Sortkeys>. See the
L<Data::Dumper> documentation for how this value is used.

=item I<readonly>

If set to 1 the variable will be set to readonly using the Readonly module.

=back

=item I<add_verbatim>($arg)

Adds $arg verbatim into the generated module.

=item I<use>( 'Foo', 'Bar', ... )

Add "use Foo;", "use Bar;" and so on to the package. It ensures that no
packages are used twice.

=item I<create>( { option => value } )

Write the package into .pm file and try to 'use' it and warn if there is any
syntax errors. Options:

=over 4

=item I<verbose>

If set to true the package filename is printed to stdout.

=back

=item I<create_or_die>( $die_message, { option => value } )

Same like I<create>() but die on any syntax error in the created package.
If given, I<$die_message> will be printed if the package fails perl's eval.
Options:

=over 4

=item I<verbose>

If set to true the package filename is printed to stdout.

=back

=back

=head1 SEE ALSO

L<Data::Dumper>

=head1 AUTHOR

Nazri Ramliy, E<lt>ayiehere@gmail.comE<gt>

=head1 SOURCE CODE

https://github.com/holygeek/Code-Generator-Perl

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Nazri Ramliy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
