# $Id: StyleSheet.pm,v 1.1.1.1 2001/03/30 23:40:02 rrwo Exp $

package RTF::StyleSheet;

require 5.005_62;
use strict;
use warnings::register qw( RTF::StyleSheeyt );

use RTF::Group  1.20;
use RTF::FontTable;
use RTF::ColorTable;
use RTF::Character;

our @ISA = qw( RTF::Group );

our $VERSION = '0.99';

use Carp;

sub _name_slot($)

# Generate slot names for properties

  {
    my $property = shift;
    return join("::", __PACKAGE__, $property);
  }

sub _initialize

# Initialize the RTF::StyleSheet object

{
    my $self = shift;
    $self->SUPER::_initialize();
    $self->append( '\stylesheet' );
    $self->{ _name_slot 'FONTTABLE'}  = RTF::FontTable->new();
    $self->{ _name_slot 'COLORTABLE'} = RTF::ColorTable->new();
}

BEGIN
  {
    foreach my $attr (qw( fonttable colortable ))
      {
	no strict 'refs';
	my $method = "get_$attr";
	*$method = sub {
	  my $self = shift;
	  return $self->{ _name_slot uc($attr) }
	};
      }
  }

sub add_font
  {
    my $self = shift;
    my $grp  = $self->get_fonttable();
    $grp->add_font(@_);
  }

sub add_color
  {
    my $self = shift;
    my $grp  = $self->get_colortable();
    $grp->add_color(@_);
  }


1;
__END__

=head1 NAME

RTF::StyleSheet - Class for generating RTF style sheets

=head1 DESCRIPTION

This is a stub module to be developed in the future.

=head1 SYNOPSIS

  use RTF::StyleSheet

=head1 METHODS

=head2 add_font

=head2 add_color

=head2 get_fonttable

=head2 get_colortable

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




