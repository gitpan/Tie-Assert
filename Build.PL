use strict;
use warnings;
use Module::Build;
my $build = Module::Build->new (
  module_name 	 => 'Tie::Assert',
  license 	 => 'perl',

  required       => {
    'B::'        => 1.02,
    'B::Flags'   => 0.01,
  },

  build_requires => {
    'Test::More' => 0.47,
  },

  dist_author    => 'Paul Golds <Paul.Golds@GMail.com>',
  
  # We've got a test tree
  recursive_test_files => 1,
);
$build->create_build_script;
