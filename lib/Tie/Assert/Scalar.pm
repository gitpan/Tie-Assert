package Tie::Assert::Scalar;
use strict;
use warnings;
use Carp;
use Tie::Assert;
use base qw/Tie::Assert/;

our $VERSION = '0.1_01'; 

sub TIESCALAR {
  my $class = shift;
  my $self = bless {_filters => {}}, $class;
  while (my $filter_name = shift) {
    $self->add_check($filter_name, shift);
  }
  return $self;
}

sub FETCH {
  my ($self) = @_;
  return $self->{_value};
}

sub STORE {
  my ($self, $value) = @_;
  if (Tie::Assert->is_enabled) {
    for my $filter (keys %{$self->{_filters}}) {
      next if $self->{_filters}{$filter}->($value);
      if (exists $self->{_handler}) {
        $self->{_handler}($filter);
        return $self->{_value};
      } else {
        croak "'$filter' constraint violated";
      }
    }
  }
  return $self->{_value} = $value;
}

1;

__END__

=head1 NAME

Tie::Assert::Scalar - Scalar implementation of Tie::Assert

=head1 VERSION

This document refers to version 0.1_01 of Tie::Assert::Scalar, released
October 6th 2004.

=head1 SYNOPSIS

  See Tie::Assert for examples of use

=head1 DESCRIPTION

This is the implementation of Tie::Assert intended to apply checks to
simple scalars, whether they be numbers, strings, or references.

=head1 NOTE

This module is ALPHA code, it's seemed stable in a number
of projects but the interface is liable to change before
the final release.

=head1 BUGS

No known bugs at present.

=head1 SEE ALSO

Tie::Aspect::CheckFactory, Tie::Aspect

=head1 AUTHOR

Paul Golds (Paul.Golds@GMail.com)

=head1 COPYRIGHT

Copyright (c) 2004, Paul Golds.  All Rights Reserved.
This module is free software.  It may be used, redistributed,
and/or modified under the same terms as Perl itself.

