#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/; # TODO: tests => 164; 

BEGIN {
  diag "Testing modules can be use'd";
  use_ok('Tie::Assert');
  use_ok('Tie::Assert::Array');
  use_ok('Tie::Assert::Scalar');
  use_ok('Tie::Assert::CheckFactory');
}

diag "Testing module supports public interface";

{
  my $assert = Tie::Assert->_new();
  can_ok($assert, qw/enable disable is_enabled/);
}

{
  my $a;
  tie $a, 'Tie::Assert::Scalar';
  can_ok(tied($a), qw/
    add_check
    count_filters
    set_error_handler
    remove_check
    remove_all_checks
    filter_names
  /); 
}

{
  my $factory = Tie::Assert::CheckFactory->new();
  can_ok ($factory, qw/
    array_ref code_ref glob_ref hash_ref lvalue_ref min max range ref_to
    scalar_ref number_ok integer_ok string_ok isa lvalue_ref regex
    can
  /);
}

diag "Testing Tie::Assert::Scalar";
{
  my $a;
  ok (tie($a, 'Tie::Assert::Scalar'), 'Can do simple no-argument tie');
}

{
  my $a;
  tie $a, 'Tie::Assert::Scalar';
  ok( $a=23, 'Can set simple no-arg tied variable');
  is( $a, 23, 'Variable has expected value');
}

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar', Under100 => sub { shift() < 100 }),
    'Can tie variable with simple closure limit');
  is_deeply(
    [tied($a)->filter_names],
    [qw/Under100/],
    'FilterNames contains the one expected item'
  );
  eval {
    $a = 5;
  };
  is ($@, '', 'Can set variable to valid value with no error');
  is ($a, 5, 'Variable has assigned value');
  eval {
    $a = 150;
  };
  ok ($@=~ m/^\'Under100\' constraint violated/,
    'Cannot set variable to invalid value');
  is ($a, 5, 'Variable has retained valid value');
  is (tied($a)->remove_all_checks, 1, 'Returned number of filters removed');
  eval {
    $a = 150;
  };
  is ($@, '', 'Can now store values which would have failed filter');
  is ($a, 150, 'Value has indeed been set');
}  

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar', 
    Under500 => sub { shift() < 500},
    Over150  => sub { shift() > 150},
  ), 'Can tie variable with multiple simple closure limits');
  is_deeply(
    [tied($a)->filter_names],
    [qw/Over150 Under500/],
    'FilterNames returned both expected items');
  eval {
    $a = 200;
  };
  is ($@, '', 'Can set variable to valid value with no error');
  eval {
    $a = 505;
  };
  ok ($@ =~ /^\'Under500\' constraint violated/,
    'First closure limit seems to work');
  is ($a, 200, 'Value unchanged');
  eval {
    $a = 100;
  };
  ok ($@ =~ /^\'Over150\' constraint violated/,
    'Second closure limit seems to work');
  is ($a,200, 'Value unchanged');
  tied($a)->remove_check('Under500');
  is_deeply(
    [tied($a)->filter_names],
    [qw/Over150/],
    'FilterNames now has only the one remaining filter');
  eval {
    $a=1000;
  };
  is ($@, '', 'Can now store values which would have failed removed filter');
  is ($a, 1000, 'Value did indeed change');
  eval {
    $a = 10;
  };
  ok ($@ =~ /^\'Over150\' constraint violated/,
    'Second closure limit seems to work');
  is ($a, 1000, 'Value still unchanged');
}

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    isOdd => \&isOdd 
  ), 'Can use function names as filters');
  eval {
    $a = 1;
  };
  is ($@, '', 'Can store valid values');
  eval {
    $a = 2;
  };
  ok ($@=~ /^\'isOdd\' constraint violated/, 'Can not store invalid values');
  is ($a, 1, 'Value remains unchanged');
}

{ 
  my  $a;
  ok (tie ($a, 'Tie::Assert::Scalar'), 'Can create simple tied variable');
  ok (tied($a)->add_check( addedIsOdd => \&isOdd), 'Added custon filter');
  is_deeply(
    [ tied($a)->filter_names],
    [ qw/addedIsOdd/ ],
    'FilterNames reports we\'ve added the new filter',
  );
  eval {$a = 15};
  is ($@, '', 'Can assign odd numbers');
  is ($a, 15, 'Value changed correctly');
  eval {$a = 2};
  ok ($@ =~ /^\'addedIsOdd\' constraint violated/, 'Rejects even numbers');
  is ($a, 15, 'Value remains unchanged');
}

diag "Testing Tie::Assert::Array";
{
  my @a;
  ok (tie (@a, 'Tie::Assert::Array'), 'Can do simple no-arg ties');
}
{
  my @a;
  ok (
    tie (@a, 'Tie::Assert::Array',
      index_filters => {
        maxCheck => Tie::Assert::CheckFactory->max(100),
      },
    ), 
    'Can do single filter index tie'
  );
  eval {$a[99] = 'Okay'};
  is ($@, '', 'Can safely assign to valid index');
  is ($#a, 99, 'Array is expected size');
  is ($a[99], 'Okay', 'Value is set as expected');
  eval {$a[101] = 'NOK'};
  ok ($@ =~ /^\'maxCheck\' index constraint violated/,
    'Cannot set value of invalid index');
  is ($#a, 99, 'Array size unchanged');
  eval {$a[23] = 120};
  is ($@, '', 'Index filters do not apply to values');
}
{
  my @a;
  ok (
    tie (@a, 'Tie::Assert::Array',
      value_filters => {
        maxCheck => Tie::Assert::CheckFactory->max(100),
      },
    ), 'Can do single filter array tie'
  );
  eval {$a[23] = 99};
  is ($@, '', 'Can assign valid values');
  is ($a[23], 99, 'Value set as expected');
  eval {$a[23] = 101};
  ok ($@ =~ /^\'maxCheck\' value constraint violated/,
    'Cannot assign invalid values');
  is ($a[23], 99, 'Value unchanged');
  eval {$a[101] = 23};
  is ($@, '', 'Value filters do not apply to indexes');
}
{
  my @a;
  ok (
    tie (@a, 'Tie::Assert::Array',
      index_filters => {
        minCheck => Tie::Assert::CheckFactory->min(10),
        maxCheck => Tie::Assert::CheckFactory->max(100),
      },
      value_filters => {
        minCheck => Tie::Assert::CheckFactory->min(500),
        maxCheck => Tie::Assert::CheckFactory->max(1000),
      },
    ), 'Can tie to multiple value and index filters',
  );
  eval { $a[12] = 750 };
  is ($@, '', 'Can assign valid values to valid indexes');
  eval { $a[9]  = 750 };
  ok ($@ =~ /^\'minCheck\' index constraint violated/,
    'Min Check works on indexes');
  eval { $a[101]  = 750 };
  ok ($@ =~ /^\'maxCheck\' index constraint violated/,
    'Max Check works on indexes');
  eval { $a[50] = 499 };
  ok ($@ =~ /^\'minCheck\' value constraint violated/,
    'Min check works on values');
  eval { $a[50] = 1001 };
  ok ($@ =~ /^\'maxCheck\' value constraint violated/,
    'Max check works on values');

  ok (!(tied(@a)->remove_index_check('nosuch')),
    'Removing non-existant index filter returns false');
  ok (!(tied(@a)->remove_value_check('nosuch')),
    'Removing non-existant value filter returns false');
  
  ok (tied(@a)->remove_index_check('minCheck'),
    'Can remove minCheck index filter');
  eval { $a[9]  = 750 };
  is ($@, '', 'Min check removed from index filters');
  eval { $a[50] = 499 };
  ok ($@ =~ /^\'minCheck\' value constraint violated/,
    'Min check still applies to values');
  ok (tied(@a)->remove_value_check('minCheck'),
    'Can remove minCheck value filter');
  eval { $a[50] = 499 };
  is ($@, '', 'Min check removed from value filters');

  ok (tied(@a)->remove_value_check('maxCheck'),
    'Can remove maxCheck value filter');
  eval { $a[50] = 499 };
  is ($@, '', 'Max check removed from value filters');
  eval { $a[10000] = 150 };
  ok ($@ =~ /^\'maxCheck\' index constraint violated/,
    'Max check still applies to indices');
  ok (tied(@a)->remove_index_check('maxCheck'),
    'Can remove maxCheck index filter');
  eval { $a[10000]  = 150 };
  is ($@, '', 'Min check removed from index filters');
}
{
  my @a;
  ok (tie (@a, 'Tie::Assert::Array'), 'Can tie to no-check array');
  eval {$a[1] = 1 && $a[11] = 1 && $a[1] = 11};
  is ($@, '', 'No problem assigning when no filters in place');
  ok (
    tied(@a)->add_index_check(
      maxIndexCheck => Tie::Assert::CheckFactory->max(10),
    ),
    'Can add a maximum to index'
  );
  eval {$a[1] = 1};
  is ($@, '', 'No problems assigning within max');
  eval {$a[11] = 12};
  ok ($@ =~ /^\'maxIndexCheck\' index constraint violated/,
    'Can no longer assign beyond max');
  ok (
    tied(@a)->add_value_check(
      minValueCheck => Tie::Assert::CheckFactory->min(10),
    ),
    'Can add a minimum to value',
  );
  eval {$a[1] = 1};
  ok ($@ =~ /^\'minValueCheck\' value constraint violated/,
    'Can no longer assign values below min');
}
{
  my @a;
  ok (
    tie (@a, 'Tie::Assert::Array',
      value_filters => {
        maxCheck => Tie::Assert::CheckFactory->max(100),
      },
    ), 'Can do single filter array tie'
  );
  ok (
    push (@a, 10, 11, 12),
    'Can push elements onto tied array'
  );
  is (
    push (@a, 13, 15),
    5,
    'Push returns new number of items'
  );
  eval { push @a, 16, 1600 };
  ok ($@ =~ /^\'maxCheck\' value constraint violated/,
    'Cannot push out-of-range values');
  is_deeply ([@a], [10,11,12,13,15],
    'Values on stack as expected'
  );
  is (pop (@a), 15, 'Value popped as expected');
  is (pop (@a), 13, 'Value popped as expected');
  is (pop (@a), 12, 'Value popped as expected');
  is (pop (@a), 11, 'Value popped as expected');
  is (pop (@a), 10, 'Value popped as expected');
}
{
  my @a;
  ok (
    tie (@a, 'Tie::Assert::Array',
      value_filters => {
        maxCheck => Tie::Assert::CheckFactory->max(100),
      },
    ), 'Can do single filter array tie'
  );
  ok (
    unshift (@a, 10, 11, 12),
    'Can unshift elements onto tied array'
  );
  is (
    unshift (@a, 13, 15),
    5,
    'Unshift returns new number of items'
  );
  eval { unshift @a, 16, 1600 };
  ok ($@ =~ /^\'maxCheck\' value constraint violated/,
    'Cannot unshift out-of-range values');
  is_deeply ([@a], [13,15,10,11,12],
    'Values on stack as expected'
  );
  is (shift (@a), 13, 'Value shifted as expected');
  is (shift (@a), 15, 'Value shifted as expected');
  is (shift (@a), 10, 'Value shifted as expected');
  is (shift (@a), 11, 'Value shifted as expected');
  is (shift (@a), 12, 'Value shifted as expected');
}
{
  my @a;
  ok (
    tie (@a, 'Tie::Assert::Array',
      value_filters => {
        maxCheck => Tie::Assert::CheckFactory->max(100),
      },
    ), 'Can do single filter array tie'
  );
  eval {$#a = 100};
  is ($@, '', 'Can storesize');
  is ($#a, 100, 'Fetchsize returns set size');
}
{
  my @a;
  ok (
    tie (@a, 'Tie::Assert::Array',
      value_filters => {
        maxCheck => Tie::Assert::CheckFactory->max(100),
      },
    ), 'Can do single filter array tie'
  );
  eval {@a = (1,2,3,150)};
  ok ($@ =~ /^\'maxCheck\' value constraint violated/,
    'Cannot load array with invalid values');
}
{
  my @a;
 ok (
    tie (@a, 'Tie::Assert::Array',
      value_filters => {
        maxCheck => Tie::Assert::CheckFactory->max(100),
      },
    ),'Can do single filter array tie'
  );
  @a = (0,1,2,3,4,5,6,7,8,9,10);
  eval {splice (@a, 2, 2, 23, 24, 25)};
  is_deeply([@a], [0,1,23,24,25,4,5,6,7,8,9,10], 'Can splice tied array');
  eval {splice (@a, 0, 1, 101)};
  ok ($@ =~ /^\'maxCheck\' value constraint violated/,
    'Cannot splice array with invalid values');
  is_deeply([@a], [0,1,23,24,25,4,5,6,7,8,9,10], 'Array unaffected');
}
diag "Testing Tie::Assert::CheckFactory";
{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    minCheck => Tie::Assert::CheckFactory->min(100),
    maxCheck => Tie::Assert::CheckFactory->max(150),
  ), 'Can create variable tied with min and max range checks');
  eval { $a = 110 };
  is ($@, '', 'Can safely set to variable between min and max');
  is ($a, 110, 'Variable value changed correctly');

  eval { $a = 90 };
  ok ($@=~ /^\'minCheck\' constraint violated/, 'Can not store too low vals');
  is ($a, 110, 'Variable unchanged');
  eval { $a = 99 };
  ok ($@=~ /^\'minCheck\' constraint violated/,
    'Can not store just too low vals');
  eval { $a = 100 };
  is ($@, '', 'Value can be set to minimum');
  is ($a, 100, 'Value changed correctly');

  eval { $a = 200 };
  ok ($@=~ /^\'maxCheck\' constraint violated/, 'Can not store too high vals');
  is ($a, 100, 'Variable unchanged');
  eval { $a = 151 };
  ok ($@=~ /^\'maxCheck\' constraint violated/,
    'Can not store just too high vals');
  eval { $a = 150 };
  is ($@, '', 'Value can be set to maximum');
  is ($a, 150, 'Value changed correctly');

  is (tied($a)->remove_check('minCheck'), 1, 'Removed minimum limit');
  eval { $a = 99 };
  is ($@, '', 'Can now set to lower values');
  eval { $a = 200 };
  ok ($@=~ /^\'maxCheck\' constraint violated/,
    'Max limit still applies');
  is (tied($a)->remove_check('maxCheck'), 1, 'Removed maximum limit');
  eval { $a = 200 };
  is ($@, '', 'Value can now be set higher');
}

{ 
  ok (tie ($a, 'Tie::Assert::Scalar',
    rangeCheck => Tie::Assert::CheckFactory->range(3 => 18),
  ), 'Can create variable tied with a range check');
  eval { $a= 14};
  is ($@, '', 'Can set variable to valid value');
  eval { $a= 2};
  ok ($@=~ /^\'rangeCheck\' constraint violated/,
    'Minimum limit applies');
  eval { $a= 19};
  is ($a, 14, 'Value remains unchanged');
  ok ($@=~ /^\'rangeCheck\' constraint violated/,
    'Maximum limit applies');
  is ($a, 14, 'Value remains unchanged');
  eval {$a = 3};
  is ($@, '', 'Can set value to minimum');
  is ($a, 3, 'Value changed correctly');
  eval {$a = 18};
  is ($@, '', 'Can set value to maximum');
  is ($a, 18, 'Value changed correctly');
}

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    scalarRefCheck => Tie::Assert::CheckFactory->scalar_ref,
  ), 'Can create variable tied with a scalar ref check');
  my ($test, @test, %test); 
  eval {$a = 1};
  ok ($@=~ /^\'scalarRefCheck\' constraint violated/,
    'Scalar ref check blocks scalar');
  eval {$a = \@test};
  ok ($@=~ /^\'scalarRefCheck\' constraint violated/,
    'Scalar ref check blocks array ref');
  eval {$a = \%test};
  ok ($@=~ /^\'scalarRefCheck\' constraint violated/,
    'Scalar ref check blocks hash ref');
  eval {$a = sub {1} };
  ok ($@=~ /^\'scalarRefCheck\' constraint violated/,
    'Scalar ref check blocks code ref');
  eval {$a = \$test; };
  is ($@, '', 'Scalar ref check allows scalar refs');
  is ($a, \$test, 'Variable changed correctly');
}

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    arrayRefCheck => Tie::Assert::CheckFactory->array_ref,
  ), 'Can create variable tied with an array ref check');
  my ($test, @test, %test); 
  eval {$a = 1};
  ok ($@=~ /^\'arrayRefCheck\' constraint violated/,
    'Array ref check blocks scalar');
  eval {$a = \@test};
  is ($@, '', 'Array ref check allows array refs');
  is ($a, \@test, 'Value changed correctly');
  eval {$a = \%test};
  ok ($@=~ /^\'arrayRefCheck\' constraint violated/,
    'Array ref check blocks hash ref');
  eval {$a = sub {1} };
  ok ($@=~ /^\'arrayRefCheck\' constraint violated/,
    'Array ref check blocks code ref');
  eval {$a = \$test; };
  ok ($@=~ /^\'arrayRefCheck\' constraint violated/,
    'Array ref check blocks code ref');
}

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    hashRefCheck => Tie::Assert::CheckFactory->hash_ref,
  ), 'Can create variable tied with a hash ref check');
  my ($test, @test, %test); 
  eval {$a = 1};
  ok ($@=~ /^\'hashRefCheck\' constraint violated/,
    'Hash ref check blocks scalar');
  eval {$a = \@test};
  ok ($@=~ /^\'hashRefCheck\' constraint violated/,
    'Hash ref check blocks array ref');
  eval {$a = \%test};
  is ($@, '', 'Hash ref check allows array references');
  is ($a, \%test, 'Value changed correctly');
  eval {$a = sub {1} };
  ok ($@=~ /^\'hashRefCheck\' constraint violated/,
    'Hash ref check blocks code ref');
  eval {$a = \$test; };
  ok ($@=~ /^\'hashRefCheck\' constraint violated/,
    'Hash ref check blocks scalar ref');
}

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    codeRefCheck => Tie::Assert::CheckFactory->code_ref,
  ), 'Can create variable tied with a code ref check');
  my ($test, @test, %test); 
  eval {$a = 1};
  ok ($@=~ /^\'codeRefCheck\' constraint violated/,
    'Code ref check blocks scalar');
  eval {$a = \@test};
  ok ($@=~ /^\'codeRefCheck\' constraint violated/,
    'Code ref check blocks array ref');
  my $sub_ref = sub {1};
  eval {$a = $sub_ref};
  is ($@, '', 'Code ref check allows code refs');
  is ($a, $sub_ref, 'Value changed correctly');
  eval {$a = \$test; };
  ok ($@=~ /^\'codeRefCheck\' constraint violated/,
    'Code ref check blocks scalar ref');
}

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    rangeOk => Tie::Assert::CheckFactory->range(5,100),
  ), 'Can tie variable to simple range');
  $a = 10;
  is ($a, 10, 'Variable can be set to valid value');
  eval {$a = 1};
  ok($@=~ /^\'rangeOk\' constraint violated/, 'Standard die sequence works');
  is ($a, 10, 'Variable value unchanged');
  ok(tied($a)->set_error_handler(\&setVar), 'Can set new error handler');
  eval {$a = 1};
  is ($@, '', 'New error handler stops die() message');
  is (getVar(), 'rangeOk', 'New error handler returns expected string');
  is ($a, 10, 'Variable value unchanged');
}

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    noVowels => Tie::Assert::CheckFactory->regex(qr/^[^aeiou]*$/i),
  ), 'Can tie variable to regex');
  eval {$a = 'Sky'};
  is ($@, '', 'Can set variable to valid values');
  is ($a, 'Sky', 'Variable value changed');
  eval {$a = 'Kite'};
  ok ($@ =~ /^\'noVowels\' constraint violated/, 'Rejects invalid values');
  is ($a, 'Sky', 'Variable value unchanged');
}

{ 
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    integerOk => Tie::Assert::CheckFactory->integer_ok(),
  ), 'Can tie variable to integer test');
  eval {$a = 23};
  is ($@, '', 'Can set variable to integers');
  is ($a, 23, 'Variable set correctly');
  eval {$a = 2.3};
  ok ($@=~/^\'integerOk\' constraint violated/, 'Denies floats');
  is ($a, 23, 'Variable unchanged'); 
  eval {$a = 'Test'};
  ok ($@=~ /^\'integerOk\' constraint violated/, 'Denies strings');
  is ($a, 23, 'Variable unchanged'); 
  my $b;
  eval {$a = \$b};
  ok ($@=~ /^\'integerOk\' constraint violated/, 'Denies references');
  is ($a, 23, 'Variable unchanged'); 
}

{ 
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    stringOk => Tie::Assert::CheckFactory->string_ok(),
  ), 'Can tie variable to string test');
  eval {$a = 'Test'};
  is ($@, '', 'Accepts strings'); 
  is ($a, 'Test', 'Variable changes correctly'); 
  eval {$a = 23};
  ok ($@=~ /^\'stringOk\' constraint violated/, 'Denies integers');
  is ($a, 'Test', 'Variable set correctly');
  eval {$a = 2.3};
  is ($a, 'Test', 'Variable unchanged'); 
  my $b;
  eval {$a = \$b};
  ok ($@=~ /^\'stringOk\' constraint violated/, 'Denies references');
  is ($a, 'Test', 'Variable unchanged'); 
}

{ 
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    numberOk => Tie::Assert::CheckFactory->number_ok(),
  ), 'Can tie variable to number test');
  eval {$a = 23};
  is ($@, '', 'Can set variable to integers');
  is ($a, 23, 'Variable set correctly');
  eval {$a = 2.5};
  is ($@, '', 'Can set variable to floats');
  is ($a, 2.5, 'Variable set correctly'); 
  eval {$a = 'Test'};
  ok ($@=~ /^\'numberOk\' constraint violated/, 'Denies strings');
  is ($a, 2.5, 'Variable unchanged'); 
  my $b;
  eval {$a = \$b};
  ok ($@=~ /^\'numberOk\' constraint violated/, 'Denies references');
  is ($a, 2.5, 'Variable unchanged'); 
}

diag "Testing Tie::Assert";
{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    min => Tie::Assert::CheckFactory->min(5),
  ), 'Can tie variable to simple minimum');
  $a = 10;
  is ($a, 10, 'Variable can be set to valid value');
  eval {$a = 2};
  ok ($@ =~ /^\'min\' constraint violated/, 'Assertions enabled by default');
  ok (Tie::Assert->disable, 'Assertions disabled');
  eval {$a = 2};
  is ($@, '', 'Can now set variable to invalid value');
  is ($a, 2, 'Value changed correctly');
  $a = 10;
  is ($a, 10, 'Variable can be set to valid value');
  ok (Tie::Assert->enable, 'Assertions enabled');
  eval {$a = 2};
  ok ($@ =~ /^\'min\' constraint violated/, 'Rejects invalid values again');
  is ($a, 10, 'Valid unchanged');
}

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    refToSuperclass => Tie::Assert::CheckFactory->ref_to('superclass'),
  ), 'Can tie to Ref_To check');
  eval {$a=10};
  ok ($@=~/^\'refToSuperclass\' constraint violated/,'Rejects scalars');
  my $superclass = superclass->new;
  eval {$a=$superclass};
  is ($@, '', 'Allows correct references through');
  is ($a, $superclass, 'Variable value changes');
  my $subclass = subclass->new;
  eval {$a=$subclass};
  ok ($@=~/^\'refToSuperclass\' constraint violated/,'Rejects subclasses');
  is ($a, $superclass, 'Variable value unchanged');
}

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    isaCheck => Tie::Assert::CheckFactory->isa('superclass'),
  ), 'Can tie to isa check');
  eval {$a=10};
  ok ($@=~/^\'isaCheck\' constraint violated/,'Rejects scalars');
  my $superclass = superclass->new;
  eval {$a=$superclass};
  is ($@, '', 'Allows correct references through');
  is ($a, $superclass, 'Variable value changes');
  my $subclass = subclass->new;
  eval {$a=$subclass};
  is ($@, '', 'Allows subclass references through');
  is ($a, $subclass, 'Variable value changed');
}

{
  my $a;
  ok (tie ($a, 'Tie::Assert::Scalar',
    canCheck => Tie::Assert::CheckFactory->can('wibble'),
  ), 'Can tie to "can" check');
  eval {$a=10};
  ok ($@=~/^\'canCheck\' constraint violated/,'Rejects scalars');
  my $superclass = superclass->new;
  eval {$a=$superclass};
  ok ($@=~/^\'canCheck\' constraint violated/,'Rejects invalid classes');
  my $subclass = subclass->new;
  eval {$a=$subclass};
  is ($@, '', 'Allows valid subclass references through');
  is ($a, $subclass, 'Variable value changed');
  my $otherwibble=otherwibble->new;
  eval {$a=$otherwibble};
  is ($@, '', 'Allows other valid class through');
  is ($a, $otherwibble, 'Variable value changed');
}

diag ("All tests run");

sub isOdd {
  return shift() %2;
}

{
  my $var;
  
  sub getVar {
    return $var;
  }

  sub setVar {
    ($var) = @_;
  }
}

package superclass;

sub new {
  my ($class) = @_;
  return bless {}, $class;
}

package subclass;
use base qw/superclass/;

sub wibble {};

package otherwibble;

sub new {
  my ($class) = @_;
  return bless {}, $class;
}

sub wibble {};
