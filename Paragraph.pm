# $Id: Paragraph.pm,v 1.2 2001/04/11 01:03:59 rrwo Exp $

package RTF::Paragraph;

require 5.005_62;
use strict;
use warnings;

require Exporter;

use RTF::Group  1.20 qw( escape_simple );
use RTF::Character 1.01 qw(
   _rawct _range _onoff _exclu _units _opts
   formatting escape_text
);

use Convert::Units::Type;

use Carp;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  paragraph_formatting
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT;
our $VERSION = '1.01';

my %SPECIAL;

BEGIN
  {
    # To-do: RTF 1.5 Spec., page 54
    %SPECIAL = (
      reset_paragraph_style => '\pard',
    );

    @EXPORT = (keys %SPECIAL, qw( paragraph paragraph_text ) );

    foreach my $method (keys %SPECIAL)
      {
	no strict 'refs';
	*$method = sub()
	  {
	    return RTF::Group->new( { subgroup => 0 }, $SPECIAL{ $method } );
	  }
      }

  }


my %PARAGRAPH_CONTROLS =
  (
   Align            => sub { _opts ('\q', shift,
                             {
			      'left'    => 'l',
			      'right'   => 'r',
			      'justify' => 'j',
			      'center'  => 'c',
			     } ) },
						 
  );

sub paragraph_formatting(@)
  {
    my $grp = RTF::Group->new( { subgroup => 0 } );

    foreach my $atom (@_)
      {
	if (ref($atom) eq "HASH") # text properties
	  {
	    foreach my $attr (keys %$atom) {
	      if (exists($PARAGRAPH_CONTROLS{ $attr }))
		{
		  $grp->append( &{$PARAGRAPH_CONTROLS{ $attr }}
				( $atom->{$attr} ) );
		}
	      else
		{
		  $grp->append( formatting( { $attr => $atom->{$attr} } ) );
#		  croak "Unrecognized attribute: \`$attr\'";
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

sub paragraph_text(@)
  {
    my $grp = RTF::Group->new( { subgroup => 0 } );
    foreach my $atom (@_)
      {
	if (ref($atom) eq "HASH") # text properties
	  {
	    $grp->append( paragraph_formatting( $atom ) );
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

sub paragraph(@)
  {
    my $grp = RTF::Group->new( { subgroup => 0 }, paragraph_text(@_) );
    $grp->prepend( '\par' );
    return $grp;
  }

1;
__END__


=head1 NAME

RTF::Paragraph - Perl class for paragraph formatting

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
