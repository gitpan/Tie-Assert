#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;
use Module::Build::Compat;

my $build = Module::Build->new (
  # Build a standard makefile 
  create_makefile_pl   => 'traditional',

  create_readme        => 1,
  module_name 	       => 'Tie::Assert',
  license 	       => 'perl',

  requires             => {
    'B'                => 1.02,
    'B::Flags'         => 0.01,
    'Params::Validate' => 0.74,
  },

  # Fairly heavy testing requirements.
  build_requires       => {
    'Test::More'       => 0.47,
  },

  dist_author          => 'Paul Golds <Paul.Golds@GMail.com>',
 

  # We've got a test tree, good for us!
  recursive_test_files => 1,
);
$build->create_makefile_pl('traditional','Makefile.PL');
$build->create_build_script;
