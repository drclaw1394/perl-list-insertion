package List::Insertion;

use 5.024000;

use strict;
use warnings;

use Template::Plex;
use Data::Combination;
use Exporter;# qw<import>;


our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.1.0';


sub make_search;

sub import {

  shift;
  my @import=@_;
  use Data::Dumper;
  say STDERR "IMPORT:". Dumper @import;

  #Build up a 
  
  # Generate subs based on import options
  my ($package)=caller;
  
  my @spec;
  push @spec, (Data::Combination::combinations $_)->@* for @import;
  
  no strict 'refs';
  use Data::Dumper;
  for my $spec(@spec){
    $spec->{prefix}//="search";
    $spec->{type}//="string";
    $spec->{duplicate}//="left";

    my $sub=make_search $spec;
    *{$package."::".$spec->{name}}=$sub if $sub;
  }
}



my $template_base=
'
my \$middle;
my \$lower;
my \$upper;

sub {
my (\$key, \$array)=\@_;
	\$lower = 0;
  \$upper = \@\$array;
	return 0 unless \$upper;

  # TODO: Run in eval for accessor fall back
  #
		(\$middle=(\$upper+\$lower)>>1,

    \$key$accessor $condition->{$fields{type}}{$fields{duplicate}} \$array->[\$middle]$accessor
    $update->{$fields{duplicate}})
	while(\$lower<\$upper);
  
	\$lower;
}
';

my %condition=(
    string=>{
      left=>'le',
      right=>'ge',
    },
    numeric=>{
      left=>'<=',
      right=>'>='
    },

    ##################
    # pv=>{          #
    #   left=>'le',  #
    #   right=>'ge', #
    # },             #
    # nv=>{          #
    #   left=>'<=',  #
    #   right=>'>='  #
    # },             #
    #                #
    # int=>{         #
    #   left=>'<=',  #
    #   right=>'>='  #
    # }              #
    ##################
);


my %update=(
  left=>
'
  ? ($upper=$middle)
  : ($lower=$middle+1)
',

  right=>

'
  ? ($lower=$middle+1)
  : ($upper=$middle)
'
);
  


# Make a binary search optimised for types and avoid sub routine callbacks
#
sub make_search {
  my ($options)=@_;

  # Ensure at least a default value for the required fields
  #
  $options->{duplicate}//="left";
  $options->{type}//="string";
  $options->{accessor}//="";
  $options->{prefix}//="search";

  # Attempt to normalise values
  # 
  $options->{duplicate}=~s/lesser/left/;
  $options->{duplicate}=~s/greater/right/;

  $options->{type}=~s/pv/string/i;
  $options->{type}=~s/nv/numeric/i;
  $options->{type}=~s/int/numeric/i;

  $options->{name}//="$options->{prefix}_$options->{type}_$options->{duplicate}";


  #Check fields values are supported

  
  die  "Unsupported value for duplicate field: $options->{duplicate }. Must be left or right" 
    unless $options->{duplicate }=~/^(left|right)$/;
  die  "Unsupported value for type field: $options->{type}. Must be string, pv, nv or int" 
    unless $options->{type}=~/^(string|numeric)$/;
  die  "Unsupported value for type field: $options->{accessor}. Must be post dereference/method call ->..."
    unless $options->{accessor} eq "" or $options->{accessor}=~/^->/;

  my $template=Template::Plex->load( \$template_base, {condition=>\%condition, update=>\%update, accessor=>$options->{accessor}}, inject=>['use feature "signatures";']);
  my $code_str=$template->render({duplicate =>$options->{duplicate}, type=>$options->{type}});
  use feature ":all";
  use Error::Show;
  my $sub=eval($code_str);
  say STDERR Error::Show::context error=>$@, program=>$code_str if($@ or !$sub);
  say STDERR $code_str;
  #wantarray?($sub,$code_str):$sub;
  $sub;
}

1;
