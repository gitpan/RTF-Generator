# $Id: Character.pm,v 1.2 2001/04/11 01:03:59 rrwo Exp $

package RTF::Character;

require 5.005_62;
use strict;
use warnings;

require Exporter;

use RTF::Group  1.20 qw( escape_simple );

use Convert::Units::Type;

use Carp;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
   escape_text formatting
  _rawct _range _onoff _exclu _units _opts
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT;
our $VERSION = '1.01';

my %SPECIAL;

BEGIN
  {
    # To-do: RTF 1.5 Spec., page 54
    %SPECIAL = (
      reset_style         => '\plain',
      column_break        => '\column',
      line_break          => '\line',
      soft_page_break     => '\softpage',
      soft_column_break   => '\softcol',

    # We need to differentiate between special controls and special characters;
    # The user should be able to have text escaped to the appropriate special
    # characters, when possible. How is the best way to do this?

      tab                 => '\tab',
      em_dash             => '\emdash',
      en_dash             => '\endash',
      em_space            => '\emspace',
      en_space            => '\enspace',
      bullet              => '\bullet',
      left_quote          => '\lquote',
      right_quote         => '\rquote',
      left_double_quote   => '\ldblquote',
      right_double_quote  => '\rdblquote',
      nonbreaking_space   => '\~',
      soft_hyphen         => '\-',
      nonbreaking_hyphen  => '\_',
    );

    @EXPORT = (keys %SPECIAL, qw( text ) );

    foreach my $method (keys %SPECIAL)
      {
	no strict 'refs';
	*$method = sub()
	  {
	    return RTF::Group->new( { subgroup => 0 }, $SPECIAL{ $method } );
	  }
      }

  }

sub _rawct # raw control + values
  {
    join '', @_;
  }

sub _range # control value must be in low,high range
  {
    my ($control, $value, $low, $high) = @_;
    (($value>=$low) and ($value<=$high)) ?
      "$control$value" :
	croak "Value \`$value\' is out of range for control word \`$control\'";
  }

sub _onoff # control on/off
  {
     my ($control, $value) = @_;
    ($value) ? $control : ($control . "0");
  }


sub _exclu # either/or controls
  {
    my ($control_on, $control_off, $value) = @_;
    ($value) ? $control_on : $control_off;
  }

sub _units # convert units to control value
  {
    my ($control, $value, $unit, $low, $high) = @_;
    my $N = Convert::Units::Type::convert($value, $unit);
    if (defined($low))
      {
	croak "Value \`$value\' is out of range for control word \`$control\'",
	  if ( ($N<$low) or ($N>$high) );
      }
    return "$control$N";
  }

sub _opts # convert options to control value
  {
    my ($control, $value, $options) = @_;
    unless ($options->{$value})
      {
	croak "Invalid value \`$value\' for control word \`$control\'",	
      }
    return $control . $options->{$value};
   }

# To-do: RTF 1.5 Spec., page 46

my %CHARACTER_CONTROLS =
  (
#    # AnimateText may qualify as the stupidest style feature yet...
#    AnimateText      => sub { my $value = lc(shift);
# 			     if ($value)
# 			       {
# 				 return _opts ('\animtext', $value,
# 				   {
# 				    'las vegas lights'    => 1,
# 				    'blinking background' => 2,
# 				    'sparkle text'        => 3,
# 				    'marching black ants' => 4,
# 				    'marching red ants'   => 5,
#                                     'shimmer'             => 6,
# 			           }
#                                  );
# 			       }
# 			     else
# 			       {
# 				 return '\animtext0';
# 			       }
#                        },
   BackgroundColor  => sub { _rawct('\cb',         shift) },
   Bold             => sub { _onoff('\b',          shift) },
   Caps             => sub { _onoff('\caps',       shift) },
   CharacterScale   => sub { _range('\charscalex', shift, 0, 100) },
   Compression      => sub { my $unit = - shift;
			   ( _units('\expnd',      $unit, '0.25pt' ),
			     _units('\expndtw',    $unit, 'twips'  ) ) },
   Deleted          => sub { _onoff('\deleted',    shift) },
   DoubleStrikethrough => sub { _onoff('\strikedl', shift) },
   Emboss           => sub { _onoff('\embo',       shift) },
   Engrave          => sub { _onoff('\impr',       shift) },
   Expansion        => sub { my $unit = shift;
			   ( _units('\expnd',      $unit, '0.25pt' ),
			     _units('\expndtw',    $unit, 'twips'  ) ) },
   Font             => sub { _rawct('\f',          shift) },
   FontSize         => sub { _units('\fs',         shift, '0.5pts' ) },
   ForegroundColor  => sub { _rawct('\cf',         shift) },
   Hidden           => sub { _onoff('\v',          shift) },
   Italic           => sub { _onoff('\i',          shift) },
   Kerning          => sub { _units('\kerning',    shift, '0.5pts' ) },
   LineHeight       => sub { _units('\softlheight', shift, '0.5pt' ) },
   Outline          => sub { _onoff('\outl',       shift) },
   Shadow           => sub { _onoff('\shad',       shift) },
   SmallCaps        => sub { _onoff('\scaps',      shift) },
   Strikethrough    => sub { _onoff('\strike',     shift) },
   Subscript        => sub { _exclu('\sub', '\nosupersub', shift )  },
   SubscriptPos     => sub { _units('\dn',         shift, '0.5pt' ) },
  );

sub formatting(@)
  {
    my $grp = RTF::Group->new( { subgroup => 0 } );

    foreach my $atom (@_)
      {
	if (ref($atom) eq "HASH") # text properties
	  {
	    foreach my $attr (keys %$atom) {
	      if (exists($CHARACTER_CONTROLS{ $attr }))
		{
		  $grp->append( &{$CHARACTER_CONTROLS{ $attr }}
				( $atom->{$attr} ) );
		}
	      else
		{
		  croak "Unrecognized attribute: \`$attr\'";
		}
	    }
	  }
	else
	  {
	    confess "I don\'t know how to handle this";
	  }
      }

    return $grp;
  }

sub text(@)
  {
    my $grp = RTF::Group->new( { subgroup => 0 } );

    foreach my $atom (@_)
      {
	if (ref($atom) eq "HASH") # text properties
	  {
	    $grp->append( formatting( $atom ) );
	  }
	elsif (ref($atom) eq "")  # plain text
	  {
	    $grp->append( escape_text( $atom ) );
	  }
	else
	  {
	    $grp->append( $atom );
	  }
      }
    return $grp;
  }


sub escape_text
  {
    my $text = escape_simple shift;
    $text =~ s/\t/\\tab/g;            # tabs
#    $text =~ s/\\(\n\r?|\r)/\\par/g;  # new paragraph
    return $text;
  }

1;
__END__

=head1 NAME

RTF::Character - Perl class for RTF character formatting

=head1 DESCRIPTION

This module exports routines which handle low-level character formatting
controls used by RTF documents for character text and style sheets.

=head1 SYNOPSIS

  use RTF::Group;
  use RTF::Character;

  my $grp = RTF::Group->new(
    text(
      reset_style(),
      { Bold => 1, FontSize => '20pt' },
      "This is some text",
      { Bold => 0, FontSize => '12pt' },
      "More text."
  );


=head1 REQUIREMENTS

The following Perl modules are required:

  RTF::Group
  Convert::Units::Type

=head1 METHODS

=head2 text

=head2 formatting

=head2 escape_text

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
