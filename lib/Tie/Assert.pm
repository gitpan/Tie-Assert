package Tie::Assert;
use strict;
use warnings;
use Tie::Assert::CheckFactory;
use Tie::Assert::Scalar;

our $VERSION = '0.1_01';
our $_assertions_enabled = 1;

# This is for test purposes only.
sub _new {
  my ($class) = @_;
  return bless {}, $class;
}

sub disable {
  $_assertions_enabled = 0;
  return 1;
}

sub enable {
  $_assertions_enabled = 1;
  return 1;
}

sub is_enabled {
  return $_assertions_enabled;
}


sub add_check {
  my ($self, $filter_name, $filter_code) = @_;
  $self->{_filters}{$filter_name} = $filter_code;
}

sub filter_names {
  my ($self) = @_;
  return sort keys %{$self->{_filters}};
}

sub remove_check {
  my ($self, $filter_name) = @_;
  my $filter_exists = exists $self->{_filters}{$filter_name};
  delete ($self->{_filters}{$filter_name});
  return $filter_exists;
}

sub remove_all_checks {
  my ($self) = @_;
  my $filter_count = $self->count_filters();
  $self->{_filters} = {};
  return $filter_count;
}

sub count_filters {
  my ($self) = @_;
  return scalar(keys %{$self->{_filters}});
}

sub set_error_handler {
  my ($self, $handler) = @_;
  $self->{_handler} = $handler;
  return 1;
}
				  
1;

__END__

=head1 NAME

Tie::Assert - Enforces restrictions on variables' contents

=head1 VERSION

This document refers to version 0.1_01 of Tie::Assert, released
October 6th 2004.

=head1 SYNOPSIS

  # Tie a few scalars...
  my $dna;
  tie ($dna, 'Tie::Assert::Scalar',
    sequenceCheck => Tie::Assert::CheckFactory->regex(qr/^[gatc]*$/i),
  );
  $dna = 'gattaca'; # Fine, it matches the regex.
  $dna = 'wibble';  # Doesn't match regex, will cause an error.

  my $percentage_score;
  tie ($percentage_score, 'Tie::Assert::Scalar',
    rangeCheck => Tie::Assert::CheckFactory->range(0 => 100),
  );
  $percentage_score = 23;  # Fine, well within the range provided.
  $percentage_score = 201; # An invalid percentage score, more errors.

  my $positive_integer;
  tie ($positive_integer, 'Tie::Assert::Scalar',
    positiveCheck => Tie::Assert::CheckFactory->min(0),
    integerCheck  => Tie::Assert::CheckFactory->integer_ok(),
  );
  $positive_number = 23;   # A valid positive number
  $positive_number = -1;   # Invalid, another error.

=head1 DESCRIPTION

Tie::Assert is designed to fill the niche when Perl developers need to
guarantee that a variable obeys certain rules at all times, times when
users of others languages would rely on assert() and type-checking.

This module is intended to be as flexible as possible, allowing the
developer to use it to do things as basic as ensuring a variable is
numeric and dying with an error message if not, up to ensuring a string
contains a valid and existing account number, and mailing a support
account if it's ever invalid.

Flexibility is the primary goal here, this module's useful for working
out where a program's setting it's variables to invalid values, to
providing a certain added level of security by ensuring variables
cannot be changed to out-of-range values.

Anywhere a value has to remain within a particular range this module
could potentially be useful.

=head1 BASIC USAGE

To use Tie::Assert in it's most common way you create a series of checks
with the methods of Tie::Assert::CheckFactory, and tie them do a variable
via the Tie::Assert::* family of modules.

For example, suppose we're going to ensure a variable is a positive number,
we can start by using the is_number() and min() functions of CheckFactory
to produce the following two checks:

  my $number_check   = Tie::Assert::CheckFactory->is_number();
  my $positive_check = Tie::Assert::CheckFactory->min(0);

Now we can create our variable and tie it to these two checks, giving them
meaningful names in the control hash for tie().  The variable's a scalar
so we'll be using Tie::Assert::Scalar as the checker.

  my $positive_number;
  
  # We're tying $positive_number to a 'Tie::Assert::Scalar' checker..
  tie ($positive_number, 'Tie::Assert::Scalar',
    # .. call the number check is_number, this'll be displayed in
    #  the error if an assignment tries to set it to something
    #  not a number..
    is_number   => $number_check,
    # .. similarly call the positive number check is_positive.
    is_positive => $positive_number,
  );

That's all there is to it.  Now if we try and assign a value to the
$positive_number variable which isn't a positive number it'll draw our
attention to the problem by quitting the program with a nice meaningful
error message.
    
=head1 ADVANCED TOPICS

=head2 Obtaining the tied object

When Perl ties a variable it creates an object which methods are called
on behind the scenes, it's this object that other methods can be called
upon to change the way the Tie::Assert class affects it.

There's a keyword named tied() which returns the object behind a given
tied variable, so we can obtain the object behind $positive_number by:

  my $positive_number_object = tied($positive_number);

If we want we can skip storing the tied object in a variable itself
and simply call methods directly on it, it's this format that'll be used
below.

=head2 Adding and removing checks on the fly

Sometimes it's convenient to be able to change the checks on a variable
at run time, and here's where you want to be able to add and remove
checks from the variable yourself rather than just relying on those
configured by the tie().

To add a check call add_check() on the tied object, providing it
with a check name and check as you did in the constructor.

  tied($variable)->add_check(
    oneToTen => Tie::Assert::CheckFactory->range(1=>10),
  );

If there was already a check assigned to the variable with the given
name then it will be replaced by the new one.

To remove a check call remove_check() providing it with the check
name only.

  tied($variable)->remove_check('oneToTen');

A final removal method remove_all_checks() will destroy all of the
checks on a given variable.

  tied($variable)->remove_all_checks();

=head2 Obtaining information on the current checks

There's a couple of methods to query the filters assigned to a given
variable, the first is a simple count of the number of filters
currently attached to a variable:

  print "Currently  ",tied($variable)->count_filters," filters\n";

A complete list of filters can be obtained by calling the 
filter_names() method:

  for my $filter_name (tied($variable)->filter_names) {
    print "Got filter $filter_name\n";
  }
  
=head2 Changing the error handler

Often the developer doesn't want the entire program to die when it's
given an invalid value, they simply want it to log it, or even just
ignore the assignment.  The Tie::Assert system handles this through
the set_error_handler() method that all tie'able classes in the
system support, to use it simply call set_error_handler() on the
tied object (See 'Obtaining the tied object' above) and pass it either
a code fragment, or a code reference to a function to handle the
error.  Either way the function you provide should accept one parameter,
the name of the check.

So, if we had had a logging object with a log() method we may set the
error handler by calling:

  tied($variable)->set_error_handler(
    sub {$logger->log("Assert error, '".shift()."' check failed");
  );

If we had a method to do the logging it's even easier.

  tied($variable)->set_error_handler( \&log_assert_error );
  
  ...
  
  sub log_assert_error {
    my ($check_name) = @_;
    $logger->log("Assert error, '".$check_name."' check failed");`
  }

=head2 Providing your own custom checks

The CheckFactory provides functionality sufficient to cover the
most common uses, but sometimes there's need to be able to add
your own custom checks.

The secret here is that the CheckFactory itself simply returns
a closure which takes the value as it's sole parameter and returns
a boolean indicating whether it's allowed the value or not.
To create your own check it's just a case of providing your
own closure or function pointer with the same 'true for accept,
false for error' behavior.

So, if I wanted to add a filter based on only allowing odd
numbers..

  tied($variable)->add_check(isOdd, sub { $_[0] % 2 });

=head2 Enabling and disabling the entire Test::Assert system

Sometimes in development there's a need to have stringent checking,
but when it hits live the error handler slows the process down too
much.

The ideal solution to this is to replace the error handler with a
lighter version, thus keeping Tie::Assert's checks in the most
vital environment, but for times when this is not required it's
possible to disable the entire Tie::Assert framework with one
single call.

  Tie::Assert->disable;

... will turn off all assertions, allowing any values to be stored
again, and ...

  Tie::Assert->enable;

... will again enable the assertions, with none of the configuration
of them lost during their disabled time.

Note that the global enabling and disabling of the Assert system
will not change the filters reported as being attached to a variable,
they're still attached there even when they're not active.

=head1 NOTE

This module is ALPHA code, it's seemed stable in a number
of projects but the interface is liable to change before
the final release.

Developments expected in future versions include:

=over 4

=item Adding Tie::Assert::Array

This should allow the use of assertions on both the index and value
of an array.

=item Adding Tie::Assert::Hash

This should allow the use of assertions on both the key and the value
of a hash.

=item Boolean Checks

Composite methods allowing you to combine multiple checks with AND or
OR logic, or reverse the result of a single test with a NOT.

=item PresentIn Checks

Basically an enumeration, restricts the value to those provided.

=item Length Checks

Restrictions based on the length of a string.

=item More comprehensive error messages

The error handlers should also receive the value which caused the
error, and the original value.

=back

Hopefully a version with all of these changes should be released
within a week or so.

=head1 BUGS

No known bugs at present.

=head1 SEE ALSO

Tie::Aspect::CheckFactory, Tie::Aspect::Scalar

=head1 AUTHOR

Paul Golds (Paul.Golds@GMail.com)

=head1 COPYRIGHT

Copyright (c) 2004, Paul Golds.  All Rights Reserved.
This module is free software.  It may be used, redistributed,
and/or modified under the same terms as Perl itself.


