package Tie::Assert::CheckFactory;
use strict;
use warnings;
use B;
use B::Flags;
use Tie::Assert;

our $VERSION = 0.1; 

# A collection of closures so we're able to produce them as flyweights.
our $_closures = {
  _can        => {},
  _max        => {},
  _min        => {}, 
  _range      => {},
  _ref_to     => {},
  
  _integer_ok => sub { _flags(shift) =~ /\bIOK\b/},
  _number_ok  => sub {
    my ($var) = @_;
    (_flags($var) =~ /\bNOK\b/) or 
    (_flags($var) =~ /\bIOK\b/)
  },
  _string_ok  => sub { _flags(shift) =~ /\bPOK\b/},

};

sub new {
  my ($class) = @_;
  my $self = bless {}, $class;
  return $self;
}

# The factories are either OO or procedural dependant upon call type.
#  The actual $self is ignored for OO.
sub array_ref {
  return ref_to('','ARRAY');
}

sub can {
  my ($self, @can) = @_;
  
  # Produce unique string.
  @can = sort @can;
  my $can = join "\n", @can;
  unless (exists $_closures->{_can}{$can}) {
    $_closures->{_can}{$can} = sub {
      my ($obj) = @_;
      return 0 unless ref($obj);
      for my $func_name (@can) {
        return 0 unless $obj->can($func_name);
      }
      return 1;
    }
  }
  return $_closures->{_can}{$can};
}
  
sub code_ref {
  return ref_to('','CODE');
}

sub glob_ref {
  return ref_to('','GLOB');
}

sub hash_ref {
  return ref_to('','HASH');
}

sub integer_ok {
  return $_closures->{_integer_ok};
}

sub isa {
  my ($self, $type) = @_;
  unless (exists $_closures->{_isa}{$type}) {
    $_closures->{_isa}{$type} = sub {
      (ref($_[0]) and $_[0]->isa($type))
    };
  }
  return $_closures->{_isa}{$type};
}

sub lvalue_ref {
  return RefTo('LVALUE');
}

sub min {
  my ($self, $min) = @_; 
  unless (exists $_closures->{_min}{$min}) {
    $_closures->{_min}{$min} = sub { $_[0] >= $min };
  }
  return $_closures->{_min}{$min};
}

sub max {
  my ($self, $max) = @_;
  unless (exists $_closures->{_max}{$max}) {
    $_closures->{_max}{$max} = sub { shift() <= $max };
  }
  return $_closures->{_max}{$max};
}

sub number_ok {
  return $_closures->{_number_ok}; 
}

sub range {
  my ($self, $min, $max) = @_;
  my $range = "${min}:${max}";
  unless (exists $_closures->{_range}{$range}) {
    $_closures->{_range}{$range} = sub {
      my $num = shift();
      return (($num <= $max) and ($num >= $min));
    }
  }
  return $_closures->{_range}{$range};
}

sub ref_to {
  my ($self, $type) = @_;
  unless (exists $_closures->{_ref_to}{$type}) {
    $_closures->{_ref_to}{$type} = sub {
      my $ref_type = ref(shift);
      return ((defined $ref_type) and ($ref_type eq $type));
    }
  }
  return $_closures->{_ref_to}{$type};
}

sub regex {
  my ($self, $regex) = @_;
  # TODO: Can we cache these safely?
  return sub { shift() =~ $regex };
}

sub scalar_ref {
  return ref_to('','SCALAR');
}

sub string_ok {
  return $_closures->{_string_ok};
}

sub _flags {
  my ($variable) = @_;
  return B::svref_2object(\$variable)->flagspv;
}

1;

=head1 NAME

Tie::Assert::CheckFactory - Creates checks for Tie::Assert

=head1 VERSION

This document refers to version 0.1 of Tie::Assert::CheckFactory,
released Oct 4th 2004.

=head1 SYNOPSIS

  # Create a $age variable which needs to be in the range of
  #  zero to a hundred and twenty.
  my $age;
  tie ($age, 'Tie::Assert::Scalar',
    Tie::Assert::CheckFactory->range(0=>120),
  );

  # Perfectly fine..
  $age = 23;

  # ..causes fatal error.
  $age = 1723;

=head1 DESCRIPTION

This module contains prebuilt useful checks for the Tie::Assert
module, to use the checks simply include them when you tie() a
variable to Tie::Assert::Scalar (..or it's relatives), or pass
them in with the add_check() method.

See the documentation for Tie::Assert for more information.

=head2 CONSTRUCTOR AND INITIALISATION

Tie::Assert::CheckFactory methods can be called in either OO or
procedural style, it makes no difference.  The following two
code fragments are effectively identical:

  my $factory = Tie::Assert::CheckFactory->new();
  $name->add_filter($factory->regex(qr/^[A-Z][A-Za-z]+$/);

  $name->add_filter(
    Tie::Assert::CheckFactory->regex(qr/^[A-Z][A-Za-z]+$/);

If you choose to use the OO-style calls the constructor takes no
parameters.

=head2 CLASS/OBJECT METHODS

As mentioned under 'CONSTRUCTOR AND INITIALISATION' above, the
following can be called either procedurally or in an object-oriented
style as you see fit.

=over 4

=item array_ref ()

The variable must contain an array reference.

=item can (@methods)

The variable must contain an object reference which supports the
listed @methods.

=item code_ref ()

The variable must contain a code reference.

=item glob_ref ()

The variable must contain a glob reference.
(Currently untested)

=item hash_ref ()

The variable must contain a hash reference.

=item integer_ok ()

The variable must be an integer.

=item isa ($class)

The variable must contain an object reference which must either be
of type $class, or a descendant.

=item lvalue_ref ()

The variable must contain an lvalue reference.
(Currently untested)

=item min ($min)

The variable cannot be lower than $min.

=item max ($max)

The variable cannot be larger than $max.

=item number_ok ()

The variable must have a numeric value.

=item range ($min, $max)

The variable must be in the range $min-$max, inclusive.

=item ref_to ($type_name)

The variable must contain a reference to the supplied
typename, often the name of a class the variable is to
store.

Note that the standard array, code, glob, hash, lvalue,
and scalar types are already covered  by other methods
provided by this class, such as array_ref, but you can
call this yourself if you wish.

=item regex (qr/regex/i)

The variable must match the regular expression provided.

=item scalar_ref ()

The variable must be a reference to a scalar.

=item string_ok ()

The variable must remain a valid string, it won't be stringified
in order to comply.

=back

=head1 BUGS

No known bugs.

=head1 NOTE

This module is ALPHA code, it's seemed stable in a number
of projects but the interface is liable to change before
the final release.

=head1 SEE ALSO

Tie::Aspect, Tie::Aspect::Scalar

=head1 AUTHOR

Paul Golds
(Paul.Golds@GMail.com)

=head1 COPYRIGHT

Copyright (c) 2004, Paul Golds.  All rights reserved.
This module is free software.  It may be used, redistributed,
and/or modified under the same terms as Perl itself.

