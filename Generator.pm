# $Id: Generator.pm,v 1.2 2001/04/11 01:03:59 rrwo Exp $

package RTF::Generator;

require 5.005_62;
use strict;
use warnings::register qw( RTF::Generator );

require Exporter;

use RTF::Group      1.20;
use RTF::FontTable;
use RTF::ColorTable;
use RTF::StyleSheet;
use RTF::Character;
use RTF::Paragraph;
use RTF::Section;

our @ISA = qw( Exporter RTF::Group );

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT    = (
  @RTF::Character::EXPORT,
  @RTF::Paragraph::EXPORT,
  @RTF::Section::EXPORT,
);

our $VERSION = '1.00';

use Carp;

sub add_color
  {
    my $self = shift;
    my $colortable = $self->get_colortable();
    $colortable->add_color(@_);
  }

sub add_font
  {
    my $self = shift;
    my $fonttable = $self->get_fonttable();
    $fonttable->add_font(@_);
  }

sub set_default_font
  {
    my $self = shift;
    my $fonttable = $self->get_fonttable();
    $fonttable->set_default(@_);
  }


sub add_text
  {
    my $self  = shift;
    $self->append(
      section_text( @_ )
    );
  }

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

    $self->set_version   ( );
    $self->set_charset   ( 'ansi' );

    my $stylesheet = RTF::StyleSheet->new();

    $self->set_stylesheet( $stylesheet );
    $self->set_fonttable ( $stylesheet->get_fonttable() );
    $self->set_colortable( $stylesheet->get_colortable() );

    $self->append(
       \& _ctrl, [$self, 'rtf', 'version'],      # RTF version
       \& _attr, [$self, 'charset'],             # Character Set
       \& _deffont, [ $self ],                   # Default Font
       $self->get_fonttable(),                   # Font Table
       $self->get_colortable(),                  # Color Table
       $self->get_stylesheet(),                  # Style Sheet
    );
}

sub _ctrl

# Given a control word and an attribute, returns that word as a control word
# with the value of the attribute as its argument.

  {
    no warnings 'uninitialized';
    my $args = shift;
    my ($self, $ctrl, $attr) = @$args;
    return "\\" . $ctrl . $self->get_attr( $attr );
  }

sub _attr

# Given an attribute, returns that attribute as a control word.

  {
    my $args = shift;
    my ($self, $attr) = @$args;
    return "\\" . $self->get_attr( $attr );
  }

sub _deffont
  {
    my $args = shift;
    my $self = $args->[0];

    my $fonttable = $self->get_fonttable();
    if (defined($fonttable->get_default))
      {
	return "\\deff" . $fonttable->get_default;
      }
    else
      {
	if (warnings::enabled)
	  {
	    warnings::warn "No default font was specified";
	  }
	return;
      }
  }

sub get_attr($,$)
  {
    my ($self, $attr) = @_;
    unless (exists( $self->{ _name_slot uc($attr) }))
      {
	croak "No such attribute: \`$attr\'";
      }
    $self->{ _name_slot uc($attr) };
  }


sub _generate_accessors

# generate get_foo and set_foo accessor methods

  {
    my $attr = shift;

    no strict 'refs';

    my $method   = "get_$attr";
    *$method = sub {
      my $self = shift;
      $self->get_attr( $attr );
    };

    $method      = "set_$attr";
    my $allowed  = shift;

    if ($allowed)
      {
	no warnings 'uninitialized';
	*$method = sub {
	  my $self  = shift;
	  my $value = shift;
	  unless (grep /^$value$/, @$allowed)
	    {
	      croak "Cannot set \`$attr\' to \`$value\'";
	    }
	  $self->{ _name_slot uc($attr) } = $value;
	};
      }
    else
      {
	*$method = sub {
	  my $self = shift;
	  $self->{ _name_slot uc($attr) } = shift;
	};
      }

  }

BEGIN
  {
    _generate_accessors( 'version', [undef, '1'] );
    _generate_accessors( 'charset', [qw( ansi mac pc pca )] );

    foreach my $attr (qw( fonttable colortable stylesheet ))
      {
	_generate_accessors( $attr );
      }



  }

1;
__END__


=head1 NAME

RTF::Generator - Perl class for generating RTF documents

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

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
