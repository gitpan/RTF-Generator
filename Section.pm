# $Id: Section.pm,v 1.2 2001/04/11 01:03:59 rrwo Exp $

package RTF::Section;

require 5.005_62;
use strict;
use warnings;

require Exporter;

use RTF::Group  1.20 qw( escape_simple );
use RTF::Character 1.01 qw(
   _rawct _range _onoff _exclu _units _opts
   formatting escape_text
);
use RTF::Paragraph qw ( paragraph_formatting );

use Convert::Units::Type;

use Carp;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  section_formatting
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT;
our $VERSION = '1.01';

my %SPECIAL;

BEGIN
  {
    # To-do: RTF 1.5 Spec., page 54
    %SPECIAL = (
      reset_section_style => '\sectd',
      endnotes_here       => '\endnhere',
    );

    @EXPORT = (keys %SPECIAL, qw( section section_text ) );

    foreach my $method (keys %SPECIAL)
      {
	no strict 'refs';
	*$method = sub()
	  {
	    return RTF::Group->new( { subgroup => 0 }, $SPECIAL{ $method } );
	  }
      }

  }


my %SECTION_CONTROLS =
  (
   PageHeight       => sub { _units('\pghsxn',     shift, 'twips' ) },
   PageWidth        => sub { _units('\pgwsxn',     shift, 'twips' ) },
   VerticalAlign    => sub { _opts ('\vertal', shift,
                             {
			      'top'     => 't',
			      'bottom'  => 'b',
			      'justify' => 'j',
			      'center'  => 'c',
			     } ) },
  );

sub section_formatting(@)
  {
    my $grp = RTF::Group->new( { subgroup => 0 } );

    foreach my $atom (@_)
      {
	if (ref($atom) eq "HASH") # text properties
	  {
	    foreach my $attr (keys %$atom) {
	      if (exists($SECTION_CONTROLS{ $attr }))
		{
		  $grp->append( &{$SECTION_CONTROLS{ $attr }}
				( $atom->{$attr} ) );
		}
	      else
		{
		  $grp->append(
                     paragraph_formatting( { $attr => $atom->{$attr} } ) );
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

sub section_text(@)
  {
    my $grp = RTF::Group->new( { subgroup => 0 } );
    foreach my $atom (@_)
      {
	if (ref($atom) eq "HASH") # text properties
	  {
	    $grp->append( section_formatting( $atom ) );
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

sub section(@)
  {
    my $grp = RTF::Group->new( { subgroup => 0 }, section_text(@_) );
    $grp->prepend( '\sect' );
    return $grp;
  }



1;
__END__

=head1 NAME

RTF::Section - Perl class for RTF section and page formatting

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
