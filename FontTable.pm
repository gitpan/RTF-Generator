# $Id: FontTable.pm,v 1.1.1.1 2001/03/30 23:39:52 rrwo Exp $

package RTF::FontTable;

require 5.005_62;
use strict;
use warnings::register qw( RTF::FontTable );

use RTF::Group  1.20, qw( escape_simple check_params );

our @ISA = qw( RTF::Group );

our $VERSION = '1.02';

use Carp;

sub PITCH_DEFAULT()  { 0; }
sub PITCH_FIXED()    { 1; }
sub PITCH_VARIABLE() { 2; }

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
    $self->{ _name_slot 'DEFAULT'} = undef;
    $self->{ _name_slot 'COUNT'}   = 0;
    $self->{ _name_slot 'TABLE'}   = [ ];
    $self->{ _name_slot 'INDEX'}   = { }; # index of names -> table
    $self->append( '\fonttbl' );
}

sub find_font
  {
    my ($self, $name) = @_;
    return $self->{ _name_slot 'INDEX'}->{ $name };
  }

sub add_font
  {
    my ($self, $name, $attr) = @_;

    $attr = check_params(
      $attr,
      [qw( FontFamily FontAltName NonTaggedFontName Panose Pitch Default )],
      [ ],
      {
       FontFamily => 'nil',
       Pitch      => PITCH_DEFAULT, # this should be optional
      },
      {
       FontFamily => [qw( nil roman swiss modern script decor tech bidi )],
       Pitch      => [ PITCH_DEFAULT, PITCH_FIXED, PITCH_VARIABLE ],
      }
    );

    my $font_id = $self->find_font( $name );
    if (defined($font_id))
      {
	if (warnings::enabled)
	  {
	    warnings::warn "Duplicate font was not added";
	  }
	return $font_id;
      }

       $font_id = $self->{ _name_slot 'COUNT'} ++;
    my $font    = RTF::Group->new();

    $self->{ _name_slot 'TABLE'}->[ $font_id ] = $font;
    $self->{ _name_slot 'INDEX'}->{ $name    } = $font_id;

    $font->append(
      "\\f" . $font_id,
      "\\f" . $attr->{FontFamily},
      escape_simple( $name ),
    );

    if (defined($attr->{Pitch}))
      {
	$font->append( '\fprq' . $attr->{Pitch} );
      }

    # See http://www.w3.org/Printing/stevahn.html for info on PANOSE
    if (defined($attr->{Panose}))
      {
	if (10 != @{$attr->{Panose}}) # A Font::PANOSE class to validate these?
	  {
	    croak "Invalid PANOSE number";
	  }
	$font->append( RTF::Group->new(
	  '\*\panose', join('', map { sprintf "%02x", $_ } @{$attr->{Panose}} ) )
        );
      }

    if (defined($attr->{NonTaggedFontName}))
      {
	$font->append( RTF::Group->new(
	  '\*\fname', escape_simple( $attr->{NonTaggedFontName} ) )
        );
      }

    {
      sub _altfont
	{
	  my ($self, $name, $font_id) = @_;
	  if (defined($self->find_font( $name )))
	    {
	      if (warnings::enabled)
		{
		  warnings::warn "Duplicate font was not added";
		}
	      return;
	    }
	  $self->{ _name_slot 'INDEX'}->{ $name } = $font_id;
	  return RTF::Group->new( "\\*\\falt", escape_simple( $name ) );
	}

      if ($attr->{FontAltName})
	{
	  my $alt_ref = ref($attr->{FontAltName});
	  if ($alt_ref eq "")
	    {
	      $font->append( $self->_altfont( $attr->{FontAltName} ) );
	    }
	  elsif ($alt_ref eq "ARRAY")
	    {
	      foreach my $name (@{ $attr->{FontAltName} })
		{
		  $font->append( $self->_altfont( $name ) );	      
		}
	    }
	  else
	    {
	      croak "Parameter \'FontAltName\' contains an invalid value";
	    }
	}
    }

    $font->append( ';' );

    $self->append( $font );

    # Usually the first font defined is the default

    unless ( ( defined( $self->{ _name_slot 'DEFAULT'} ) ) and
	     ( !$attr->{Default} ) )
      {
	$self->{ _name_slot 'DEFAULT'} = $font_id;
      }

  }

sub is_valid

# Tests if the font is valid.

  {
    my ($self, $font) = @_;

    unless ($self->count)
      {
	return;
      }

    return ! ( ($font<0) or ($font >= $self->count) or
	 ($font =~ /\D/) )
  }


sub set_default

# Sets the default font

  {
    my ($self, $font) = @_;
    if ($self->is_valid( $font ))
      {
	$self->{_name_slot 'DEFAULT'} = $font;
      }
    else
      {
	croak "Cannot set the default font to an invalid value";
      }
  }

sub get_default

# Returns the default font in the table

  {
    my ($self) = @_;
    return ($self->{_name_slot 'DEFAULT'});
  }

sub count

# Returns the number of fonts defined in the table.

  {
    my ($self) = @_;
    return ($self->{_name_slot 'COUNT'});
  }


1;

__END__


=head1 NAME

RTF::FontTable - Class for generating RTF document font tables

=head1 DESCRIPTION

RTF::FontTable is an RTF::Group which generates font tables for RTF
documents.

=head1 SYNOPSIS

  use RTF::FontTable;

  my $gFonts = RTF::FontTable->new();

  my $fTimes = $gFonts->add_font('Times New Roman (Western)', {
    'FontFamily'  => 'roman',
    'FontAltName' => [ 'Times' ],
    'NonTaggedFontName' => 'Times New Roman',
    'Pitch'       => 0,
    'Panose'      => [ 2, 2, 6, 3, 5, 4, 5, 2, 3, 4 ],
  } );

=head1 METHODS

RTF::FontTable is a RTF::Group. The following methods have been added:

=head2 add_font

  $font = $obj->add_font( $font_name, \%attributes );

Adds a font to the font table, or returns the font code of that font if it
is already in the font table. (If the font is in the table, it will I<not>
update the font attributes.)

Font attributes are as follows:

=over

=item FontFamily

Specifies the type of font. Acceptable values are:

=over

=item nil

the default, if C<FontFamily> is not specified or unknown,

=item swiss

sans-serif, such as "Arial" or "Helvetica",

=item roman

serif, such as "Times" or "Garamond",

=item modern

for fixed-pitch or modern screen fonts such as "Courier" or "Verdana",

=item script

for script fonts, such as "Cursive"

=item tech

for symbol fonts,

=item decor

for decorative fonts, such as "Old English", and

=item bidi

for bidirectional fonts such as Hebrew or Arabic.

=back

=item FontAltName

Specifies a list of alternate fonts or font names.  For example, an alternate
font for "Helvetica" on systems which do not have it might be "Arial" or
"Helv".

=item NonTaggedFontName

The non-tagged font name. For example, "Arial" is a non-tagged font name while
"Arial (Turkish)" is a tagged name.

=item Pitch

Specifies the font pitch. C<0> is the default, C<1> is fixed, and C<2> is
variable.

=item Panose

An array with the ten-byte PANOSE number for the font.

=item Default

If true, makes this font the default font. If multiple fonts are set as
C<Default>, the most recently added font is the default font.

=back

=head2 find_font

  if ($font = $obj->find_font( $font_name )) ...

Returns the font code if the font was added to the system. Otherwise returns
C<undef>.

=head2 get_default

  $font = $obj->get_default;

Returns the default font in the table (which is either the first font added
or the last font added the C<Default> attribute set).

=head2 set_default

  $obj->set_default( $font );

Sets the default font.

=head2 is_valid

  if ($obj->is_valid( $font )) ...

Returns true if the font code has been added to the font table.

=head2 count

  my $num_fonts = $obj->count();

Returns the number of fonts in the table.

=head1 SEE ALSO

Microsoft Technical Support and Application Note, "Rich Text Format (RTF)
Specification and Sample Reader Program", Version 1.5.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 LICENSE

Copyright (c) 2001 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



