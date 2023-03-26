use strict;
use warnings;
use feature ":all";
use List::Insertion {type=>"numeric", duplicate=>"left"};
use Benchmark qw<cmpthese>;

my @data=map rand(10), 1..$ARGV[0]//120;

# Updating/Building a sorted array is faster with built routines up to about
# 150 elements.  After that, List::Insertion takes a large lead Perl is very
# quick to sort when all the data is available ahead of time

cmpthese -1, {
  ###########################################################################
  # # An example of sorting data all at once. Assumes all data is available #
  # perl_one_shot=>sub {                                                    #
  #   my @sort=@data;                                                       #
  #   @sort=sort {$a <=> $b} @sort;                                         #
  # },                                                                      #
  ###########################################################################

  # Sorting and building array with new data using built in sort.
  perl_sort_update=>sub {
    my @sort;
    for(@data){
      push @sort, $_;
      @sort=sort {$a <=> $b} @sort;
    }
  },

  # Sorting and building array with new data using List::Insertion
  list_insertion_update=>sub {
    my @sort;
    my $pos;
    for(@data){

      if(@sort){
        $pos=search_numeric_left $_, \@sort;
        splice @sort, $pos, 0 , $_;
      }
      else{
        push(@sort, $_)
      }

    }
  }
}
;





