use Benchmark qw<cmpthese>;

use List::BinarySearch::PP;
use List::BinarySearch::XS;
use List::Insertion {type=>"nv", duplicate=>"left"};

# test
my $max=10;
my $size=1000;
my @list=sort map rand($max), 1..$size;
my @keys=map rand($max),1..10;


use feature ":all";
{
  my @res=map List::BinarySearch::PP::binsearch_pos(sub {$a <=> $b}, $_, @list), @keys;
  say join ", ", @res;
}
{
  my @res=map List::BinarySearch::XS::binsearch_pos(sub {$a <=> $b}, $_, @list), @keys;
  say join ", ", @res;
}
{
  my @res=map search_numeric_left($_, \@list), @keys;
  say join ", ", @res;
}


cmpthese -1, {
  "L::BS::PP"=>sub {

    my @res=map List::BinarySearch::PP::binsearch_pos(sub {$a <=> $b}, $_, @list), @keys;
  },
  "L::BS::XS"=>sub {

  my @res=map List::BinarySearch::XS::binsearch_pos(sub {$a <=> $b}, $_, @list), @keys;
  }, 
  "L::I"=>sub {
    my @res=map search_numeric_left($_, \@list), @keys;
  }
};


