# $Id: ColorTable.pm,v 1.1.1.1 2001/03/30 23:39:46 rrwo Exp $

package RTF::ColorTable;

require 5.005_62;
use strict;
use warnings::register qw( RTF::ColorTable );

use RTF::Group  1.20;

our @ISA = qw( RTF::Group );

our $VERSION = '1.03';

use Carp;

sub _name_slot($)

# Generate slot names for properties

  {
    my $property = shift;
    return join("::", __PACKAGE__, $property);
  }


sub _initialize

# Initialize the RTF::ColorTable object

{
    my $self = shift;
    $self->SUPER::_initialize();
    $self->{ _name_slot 'COUNT'} = 0;
    $self->{ _name_slot 'TABLE'} = [];
    $self->append( '\colortbl;' );
}

sub find_rgb
  {
    my ($self, $red, $green, $blue) = @_;

    my $i = $self->{ _name_slot 'COUNT'};
    while ($i)
    {
      $i--;
      if (
	  ($self->{_name_slot 'TABLE'}->[ $i ]->[0] == $red) and
	  ($self->{_name_slot 'TABLE'}->[ $i ]->[1] == $green) and
	  ($self->{_name_slot 'TABLE'}->[ $i ]->[2] == $blue) )
	{
	  return 1+$i;
	}
    }

    return;
  }

sub add_rgb
  {
    my ($self, $red, $green, $blue) = @_;

    foreach my $value ($red, $green, $blue)
    {
	croak "Invalid color code: \`$value\'",
	  if (($value<0) or ($value>255) or ($value =~ m/\D/));
    }

    my $color = $self->find_rgb( $red, $green, $blue );
    if ($color)
      {
	if (warnings::enabled)
	  {
	    warnings::warn "Duplicate color was not added";
	  }
	return $color;
      }

    $self->{_name_slot 'TABLE'}->[ $self->{ _name_slot 'COUNT'}++ ] = 
      [$red, $green, $blue];

    $self->append( '\red'.$red, '\green'.$green, '\blue'.$blue, ';' );

    return $self->{ _name_slot 'COUNT' };
  }

sub is_valid

# Tests if the color is valid.

  {
    my ($self, $color) = @_;

    return ! ( ($color<0) or ($color > $self->count) or
	 ($color =~ /\D/) )
  }

sub get_default

# Returns the default (or "auto") color

  {
    return 0;
  }

sub count

# Returns the number of colors defined in the table.

  {
    my ($self) = @_;
    return ($self->{_name_slot 'COUNT'})+1;
  }

BEGIN
  {
    *add_color   = \&add_rgb;
    *find_color  = \&find_rgb;
    *auto_color  = \&get_default;
  }

1;
__END__

=head1 NAME

RTF::ColorTable - Class for generating RTF document color tables

=head1 DESCRIPTION

RTF::ColorTable is an RTF::Group which generates color tables for RTF
documents.

=head1 SYNOPSIS

  use RTF::ColorTable;

  my $gColorTable = RTF::ColorTable->new();

  my $cBlack = $gColorTable->add_color(0, 0, 0);


  if (my $cBlue = $gColorTable->find_color(0, 0, 255))
    {
      print "Blue is defined";
    }

  print $gColorTable->count(), " colors defined.";

  unless ($gColorTable->is_valid( $cBlack ))
    {
      die "Invalid color";
    }

  my $cDefault = $gColorTable->auto_color();

=head1 METHODS

RTF::ColorTable is a RTF::Group. The following methods have been added:

=head2 add_color

  $color = $obj->add_color( $red, $green, $blue );

Adds the color specified by C<$red>, C<$green>, and C<$blue> to the color
table, and returns the color code. If the color is already in the table,
it turns the color code of that color.

Color names are not supported in this version. If you named colors, you
can get them from C<Graphics::ColorNames>.

This is an alias for the C<add_rgb> method (which is deprecated).

=head2 find_color

  if ($color = $obj->find_color( $red, $green, $blue ) ) ...

Returns the specified color, if it exists. Otherwise it returns C<undef>.

This is an alias for the C<find_rgb> method (which is deprecated).

=head2 auto_color

  $cDefault = $obj->auto_color();

Returns the default color (also known as the "auto color"). This is a special
color code used in RTF documents.

This is an alias for the C<get_default> method.

Generally the auto-color is left undefined, and when it is set, most RTF
readers either ignore it or confuse it with the first color. So there is
no method to set the default color.

=head2 is_valid

  if ($obj->is_valid( $color )) ...

Returns true is the color is valid (that is, it has been added to the color
table, or it is the auto color).

=head2 count

  $num_colors = $obj->count();

Returns the number of colors in the table. Because of the auto color, there
is always at least one color defined.

=head1 SEE ALSO

Microsoft Technical Support and Application Note, "Rich Text Format (RTF)
Specification and Sample Reader Program", Version 1.5.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 LICENSE

Copyright (c) 2000-2001 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut




