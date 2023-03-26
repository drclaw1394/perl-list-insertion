# NAME

List::Insertion - Binary search a list for insertion point

# SYNOPSIS

Export a subroutine to locate the index of the first instance (left) of value
in a sorted simple scalar list:

```perl
# Exports 'search_numeric_left' only
#
use List::Insertion {type=>"numeric", duplicate=>"left"};

# Data has value 30 duplcated

my @data=(10, 20, 30, 30, 40, 50, 60, 70);
#index    0   1   2   3   4   5   6   7

# The insert position will be index 2, which is left of duplicates
#
my $key= 30;
my $pos=search_numeric_left $key, \@data;

if($data[$pos] == $key){
  # Exact match, $pos is the index of the searched $key in the array (left)
}
else{
  # $pos is the index where $key should be inserted
}  
```

Same as above with string comparison:

```perl
use List::Insertion {type=>"string", duplicate=>"left"};

my @data=qw<10 20 30 30 40 50 60 70>;
#index      0  1  2  3  4  5  6  7

my $key= "30";
my $pos=search_string_left $key, \@data;

if($data[$pos] eq $key){
}
else{
}  
```

Export a subroutine to search for insertion point, of array of hashes, right of
duplicates, with accessor to comparison value:

```perl
# Data has value=>3 duplcated. Elements are hash refs so use an accessor snippet
#
use List::Insertion {type=>"numeric", duplicate=>"right", accessor=>'->{value}'};
my @data=(
  {value=>1, other=>"a"},
  {value=>2, other=>"b"},
  {value=>3, other=>"c"},
  {value=>3, other=>"d"},
  {value=>4, other=>"e"},
  {value=>5, other=>"f"},
);

# The insert position will be index 4, which is right of duplicates
#
my $key= 3;
my $pos=search_numeric_right $key, \@data;
```

Export 'make\_search' and create anonymous subroutine instead of injecting named
subroutines to name space

```perl
use List:::Insertion "make_search";

my @data=(1, 2, 3);

my $search=make_search type=>"numeric", duplicate=>"left";
my $key=2;
my $pos=$search->($key, \@data);
```

# DESCRIPTION

[List::Insertion](https://metacpan.org/pod/List%3A%3AInsertion) implements binary search algorithms to locate the
**insertion** point of a sorted list for a given value. If the value were to be
inserted at that position, the list would remain sorted.

A distinction is made between inserting left or right of an exact match or
duplicated entry. This allows to insert data before contiguous equal items or
after.

Performance rather than flexibility is favoured in the implementation and
necessitates the following restrictions on the data stored in the array/list
and how it's compared:

- Data must be sorted in asscending order only

    This simplifies the combinations of subroutines exported

- No code blocks can be specified

    While code blocks are very flexible, 90% of the functionality can be achieved
    with 'accessor' snippets.

- Element comparision is implicitly numerical or string

    No object methods for comparison. Only basic `<=>`, `>=`, `le`
    and `ge` operators are used for internally for string and numeric comparison.

- List element must be homogeneous and defined 

    All items in the list are expected to have the same data structure. The
    structure  can be a simple scalar like a string or number, in which case no
    'acceesor' snippet is used. 

    On the other hand it could be complex, like an array of arrays or hashes of
    objects to any level. The only restriction in this case is the 'accessor'
    snippet is able to access the value for comparison via post dereferencing or
    method calls

Although intended for searching for a insertion point, this module can also be
used for general searching of elements. A simple check of equality between the
search key and  value at the found index will determine if the value was
actually found or not.

The returned index will never indicate 'not found' as there is always a insert
location in a list.

No symbols are exported by default. Specifications given at import time are
used to generate and export the search routine (s) needed. Anonymous search
subroutines can also be generated.

# WHEN TO USE

## Building/Updating an Already Sorted List

Perl is pretty fast when sorting bulk array data in a single sort call. However
adding a single new value and resorting an existing array is not nearly as
fast.

Normally to update an already sorted array with a new value, you would push the
new value to the list and resort. This module can improve performance by first
locating the insert point at which you would splice in the new value. For
example:

```perl
eg.
  
  # Performance Cross over point is around 120-130 elements

  my @data= map rand(10), 1..1000; 

  my $key=4.3;

  # Instead of this ...
  #
  my @perl_sort;
  push @perl_sort, $key;
  @perl_sort=sort {$a <=> $b} @perl_sort;

  # Do this ...
  #
  my @sorted;
  my $pos;
  if(@sort){
    $pos=search_numeric_left $key, \@sorted;
    splice @sorted, $pos, 0, $key;
  }
  else {
    push @sorted, $key;
  }
```

A benchmarking script demonstrating this included in the distribution:

```
Results for contructing/sorting an array with 1000 random numeric elements
one element at a time

                       Rate      perl_sort_update list_insertion_update
perl_sort_update      198/s                    --                  -78%
list_insertion_update 881/s                  345%                    --
```

## Pure Perl Performance

This module gives better pure perl binary search performance than similar
modules using code blocks for comparison. If you don't need the full
flexibility of a CODE block to act as a comparison, then this module can give
you a nice speed boost. If you using an XS module then that most likely would
still be faster.

A benchmarking script demonstrating this included in the distribution:

```
Searching a 10000 element numeric sorted list, compared with
List::BinarySearch::PP and List::BinarySearch::XS

              Rate L::BS::PP      L::I L::BS::XS
L::BS::PP  12667/s        --      -83%      -91%
L::I       74472/s      488%        --      -49%
L::BS::XS 144807/s     1043%       94%        --
```

# API

## Importing

When importing this module, the type of comparison (string or numeric) and the
behaviour in dealing with duplicate values (left or right) is specified along
with optional accessor and prefix options.

Combinations of these options are generated via `Data::Combination`, allowing
multiple subroutines to be configured and returned with minimal typing.

Consider the following examples:

```perl
use List::Insertion {type=>"numeric", position=>left};                #(1)

use List::Insertion {type=>"numeric", position=>["left", "right"]};   #(2)

use List::Insertion {                                               #(3)
  type=>"numeric", duplicate=>["left", "right"], accessor=>'->{hash_key}'
};

use List::Insertion {                                               #(4)
  type=>"numeric", duplicate=>["left", "right"], accessor=>'->{hash_key}->method',
  prefix=>"find"};
```

1. Imports the subroutine "search\_numeric\_left"
2. Imports the subroutines "search\_numeric\_left" and "search\_numeric\_right"
3. Imports the subroutines "search\_numeric\_left" and "search\_numeric\_right" and
uses the accessor '->{hash\_key} when accessing elements. Elements must all be
hash references and the hash key will be compared in numeric fashion.
4. Imports the subroutines "find\_numeric\_left" and "find\_numeric\_right" and uses
the accessor '->{hash\_key}->method' when accessing elements. Elements must all
respond to 'method', with its return value compared in numeric fashion.

The default values of supported options are used if no matching options are
present in an import specification. The defaults are:

```perl
type=>"string",
duplicate=>"left",
accessor=>"",
prefix=>"search"
```

Supported options during importing include:

### type

```perl
type=>NAME or type=[NAME,...]
```

A plain scalar or array ref of comparison type names. The type is implicitly
used as the second part of an exported subroutines name. Supported values for
NAME
are:

- numeric

    Numerical comparison

- string

    String comparison

### duplicate

```perl
duplicate=>SIDE  or pos=>[SIDE,...]
```

A plain scalar or array ref of side names. The side to choose when duplicate
values are encountered. This is used implictily as the last part of an exported
subroutines name.

Supported values for SIDE are:

- left, lesser

    Choose the lower index when the duplicate items are encountered.

    ```perl
    eg 
      my @list=( 10, 20, 20, 20, 30)
                    /\
                    ||

      A 'left' search for 20 will result in a index of 1
    ```

- right, greater 

    Choose the greater index (after duplicates) when the duplicate items are
    encountered.

    ```perl
    eg  
      my @list=( 10, 20, 20, 20, 30)
                                /\
                                ||
      A 'right' search for 20 will result in a index of 4
    ```

### accessor

```perl
accessor=>STRING
```

A string consisting of perl post dereferencing/method call syntax, which is
used is to access internal levels of a element's data structure. Internally
this string is literally appending to the array element indexing code:

```
eg
  Acessor: ->{hash_ref}[array_deref]->method
  Interal code: ... $array[$index] ...

  Resulting code: ... $array[$index]->{hash_ref}[array_deref]->method ...
```

If not specified, it is treated as an empty string, and elements in the list
are treated as numeric/string simple scalars. Their value are used directly in
comparisons in the search algorithm.

If specified, elements are dereferenced/called with the accessor. The resulting
value is used in the comparison in the search algorithm.

The value of the search key is NOT subject to the accessor and is used directly
in comparison.

### prefix

```perl
prefix=>STRING
```

A string which becomes the start of the imported subroutines name. If
unspecified, the string "search" is used.

```perl
eg 
  use List::Insertion {prefix=>"my_searcher", ...};

  # The subrotine imported will start with my_searcher

  my $pos=my_searcher_...
```

## Using Generated/Exported subrotines

The generated/imported subroutines are named in the format:

```
prefix_type_duplicate
```

where prefix, type and duplicate represent the prefix, data type ( string or
numeric) and duplicated entry handling configuration

Routines are called with two arguments, the search key and reference to the sorted data:

```perl
my $insert=find_nv_left $key, \@data;
```

The return value is the index in the `@data`, which if inserting `$key` will
keep the list sorted.

The value of the element located at `$insert` my be equal to the search key.

**NOTE:** Search routines never return less then 0 or otherwise indicate
'element not found'. The index is always the point when data can be inserted.
So an empty list will always return a found index of 0, as this where element
would be inserted.

## Annonymous Subroutines

Instead of importing named subroutines into your namespace, anonymous
subroutines can be generated by importing the `make_search` subroutine:

```perl
use List::Insertion "make_search";
```

### make\_search

```perl
my $sub=make_search {options}
```

Creates a search subroutine configured with a options hash ref. Each option is
a key value pair, as described in the **importing** section. Only simple scalars
key/values are allowed, as only a single subroutine is returned per call.
Multiple calls to this subroutine will need to be used to generate multiple
search subroutines.

This is the subroutine called internally during import to generate the named
subroutines.

The option **prefix** has no effect as the routine is anonymous.

# FUTURE WORK

- Make an XS version

    That could be tricky with the accessor feature.

- Validate accessor

    Add a 'validator' for testing/confirmation of accessor syntax

# SEE ALSO

[List::BinarySearch](https://metacpan.org/pod/List%3A%3ABinarySearch) and the [List::BinarySearch::PP](https://metacpan.org/pod/List%3A%3ABinarySearch%3A%3APP)(pure perl)  and
[List::BinarySearch::XS](https://metacpan.org/pod/List%3A%3ABinarySearch%3A%3AXS) (XS enhanced) 'sub modules' provide more flexibility
than this module. Mainly because of the use of code blocks are for element
comparison.

However this module which is also pure perl is about 5-6x as fast as the
[List::BinarySearch::PP](https://metacpan.org/pod/List%3A%3ABinarySearch%3A%3APP) module and is only half the speed of the
[List::BinarySearch::XS](https://metacpan.org/pod/List%3A%3ABinarySearch%3A%3AXS) module.

# REPOSITORY and BUG REPORTING

Please report any bugs and feature requests on the repo page:
[GitHub](http://github.com/drclaw1394/perl-list-insertion)

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2023 by Ruben Westerberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, or under the MIT license

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.
