# $Id: Group.pm,v 1.1.1.1 2001/03/30 23:39:58 rrwo Exp $

package RTF::Group;

require 5.005_62;

our $VERSION = '1.20';

our @ISA = qw( Exporter );

our %EXPORT_TAGS = ( 'all' => [ qw(
  check_params
  escape_simple
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

use strict;
use warnings::register qw( RTF::Group );

use Carp;

our %DEFAULTS;

sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->_initialize();
    $self->_set_properties(@_);
    return $self;
}


sub _name_slot($)

# Used for generating slot names

  {
    my $property = shift;
    return join("::", __PACKAGE__, $property);
  }


sub _initialize                        # Initialize...
{
    my $self = shift;

    $self->{_name_slot 'GROUP'} = [ ]; # Define an empty group

    foreach my $prop (keys %DEFAULTS)  # Set default properties
    {
        $self->{_name_slot $prop} = $DEFAULTS{$prop};
    }
}


sub _set_properties
{
    my $self = shift;
    foreach my $arg (@_)
    {
        if (ref($arg) eq "HASH")
        {
            foreach my $prop (keys %{$arg})
            {
                if (exists($DEFAULTS{$prop}))
                {
                    $self->{_name_slot $prop} = $arg->{$prop};
                }
                else
                {		 
		  croak "Unknown property: \`$prop\'";
		}
            }
        }
        else {
            $self->append($arg);
        }
    }
}

# sub import
#   {
#     my $class       = shift;
#     my $version_req = shift || 0;

#     if ($version_req > $VERSION)
#       {
# 	croak "__PACKAGE__ $version_req required--this is only version $VERSION";
#       }
    
#     if (grep { ref($_) ne "HASH" } @_)
#       {
# 	    croak "Method exporting is not supported.";
#       }

#     my $default_attr = \ %DEFAULTS;

#     foreach my $attrs (@_)
#       {
# 	$default_attr = check_params(
# 	   $attrs,
# 	   [ keys %DEFAULTS ],
#            [ ],
#            $default_attr,
# 	   { }
#         );
	
#       }
#   }

sub append
  {
    my $self = shift;
    push @{$self->{_name_slot 'GROUP'}}, @_ ;
    return $self;
  }

sub prepend
  {
    my $self = shift;
    unshift @{$self->{_name_slot 'GROUP'}}, @_ ;
    return $self;
  }

# Escape unescaped brackets and 8-bit chaacters
sub _escape
  {
    no warnings 'uninitialized';
    my ($atom) = @_;
    $atom =~ s/[!\\]?([\{\}])/\\$1/g;
    $atom =~ s/([\x80-\xff])/sprintf("\\\'\%02x", ord($1))/eg;
    return $atom;
  }

# De-reference objects in the list, so we can print it
sub _rtf_list
  {
    my $self     = shift;             #
    my @list_out = ();                # Returns a de-referenced list
    my @list_in  = (@_) ? @_ :        # List to de-reference
      @{$self->{_name_slot 'GROUP'}}; #
    my $counter  = @list_in;          # No. of elements in list

    # Why do we decrement a counter rather than use something like
    # ``while (my $atom = shift @list_in)''? Because if the value
    # of $atom == 0, it will be treated as false even though there
    # are more elements in the list to shift!

    # We can't use "map" here since CODE references have an argument
    while ($counter--)
      {
	if ($counter<0) { confess "atom count mismatch"; }

        my $atom     = shift @list_in;
        my $ref_atom = ref($atom);

      REF_CASE: {
	  if ($ref_atom eq "ARRAY")
	    {
	      push @list_out, $self->_rtf_list(@{$atom});
	      last REF_CASE;
	    }

	  if ($ref_atom eq "SCALAR")
	    {
	      push @list_out, $$atom;
	      last REF_CASE; 
	    }

	  if ($ref_atom eq "CODE")
	    {
	      my $arg = shift @list_in; # next item is argument for subroutine
	      $counter--;               # decrement counter just in case
	      push @list_out, $self->_rtf_list( &$atom($arg) || undef );
	      last REF_CASE;
	    }

	   if ($ref_atom eq "REF")
	     {
	       push @list_out, $self->_rtf_list( $$atom );
	       last REF_CASE;
	     }

# Rather than die for unknown objects, we call the object's subgroup() and
# _rtf_list() methods in an eval { } so that descendant objects can be
# handled.  (Use with caution: this can be a bugbear if abused.)

	  if ($ref_atom ne "")
	    {
	      eval {
		if ($atom->subgroup)
		  {
		    push @list_out, [ $atom->_rtf_list() ];
		  }
		else
		  {
		    push @list_out, $atom->_rtf_list();
		  }
	      };
	      if ($@)
		{
		  croak "Don\'t know how to handle type \`$ref_atom\'";
		}
	      last REF_CASE;
	    }

	  push @list_out, $atom;
      };

    }

    return @list_out;
  }

sub _list_as_string
{
    my $self = shift;

    my ($atom, $string);

    unless (@_) { return; }

    $string = "\{";

    {
      no warnings 'uninitialized';
      my $prev = "\{";
      $string = join("",              # join elements togather, surrounded
      ( "\{", (                       #   by curley braces;
        map {                         # for each element in the list
	  if (ref($_) eq "ARRAY")     #   if it's an array reference,
	    {                         #     then add as a list-within-a-list
	      $_ = $self->_list_as_string( @{ $_ } );
	    }
	  else                        # otherwise add the element
	    {                         #
	      $_ = _escape($_), if ($self->escape);
	      $prev = ( ($_ !~ /^[\\\;\{\}]/) and ($prev !~ m/[\}\{\s]$/))
		? " $_"
		  : $_;
	    }
	} @_ ), "\}"
      ) );
    }
}

sub is_empty
{
    my $self = shift;
    return ($self->_rtf_list() == 0);
}

sub as_string
{
    my $self = shift;
    return $self->_list_as_string( $self->_rtf_list() );
}



BEGIN
  {
    no strict 'refs';
    *string = \ &as_string;           # 'string' is alias for 'as_string'

    %DEFAULTS = (
      subgroup   => 1,
      escape     => 1,
      wrap       => 0,
    );

    foreach my $attr (keys %DEFAULTS)
      {
	no strict 'refs';
	my $slot = _name_slot $attr;
	*$attr = sub {
	  my $self = shift;
	  if (@_)
	    {
	      return $self->{$slot} = (shift) ? 1 : 0;
	    }
	  else
	    {
	      return $self->{$slot};
	    }
	};
      }
  }


sub check_params

# Quick and dirty routine to check parameters. Arguments are as follows:
#  $params   = parameters passed from user
#  $allowed  = array ref of allowed paramters
#  $required = array ref of required parameters (assumes these are $allowed)
#  $defaults = hash ref of default values (assumes these are allowed)
#  $validate = hash ref of array refs with valid values for some parameters

  {
    no warnings 'uninitialized';
    my ($params, $allowed, $required, $defaults, $validate) = @_;
    my $result = { };
    map { $result->{$_} = $defaults->{$_}; } (@$allowed); # set defaults
    map { $result->{$_} = $params->{$_}; }   (@$allowed); # overwrite w/args
    map { if (!exists($result->{$_}))                     # check for invalid
	    {                                             #  parameter names
	      croak "Parameter '`$_\' is not allowed";
	    }
	} (keys %$params);
    map { unless (exists($params->{$_}))                  # check for required
	    {
	      croak "Parameter \`$_\' is required";
	    }
	} (@$required);
    map { my $value = $result->{$_};                      # validate values
          unless ( map { ($value eq $_) ? $_ : undef } @{$validate->{$_}} )
	    {
	      croak "Parameter '`$_\' contains an invalid value: \`$value\'";
	    }
	} (keys %$validate);

    return $result;
  }

sub escape_simple($)

# Simple escaping of special characters (except curley brackets {} which are
# escaped by RTF::Group). Should '*' be escaped? This may confuse RTF parsers.

  {
    my $text = shift;
    $text =~ s/([\\])/\\$1/g;        # escape special characters
    return $text;
  }


1;

__END__

=head1 NAME

RTF::Group - Base class for manipulating Rich Text Format (RTF) groups

=head1 DESCRIPTION

This is a base class for manipulating RTF groups.  Groups are stored internally
as lists. Lists may contain (sub)groups or atoms (raw text or control words).

Unlike the behavior of groups in the original C<RTF::Document module> (versions 0.63 and earlier), references to arrays (lists) are I<not> treated as subgroups, but are dereferenced when expanded (as lists or strings).

This allows more flexibility for changing control codes within a group, without
having to know their exact location, or to use kluges like I<splice> on the
arrays.

I am in the process of writing a C<RTF::Generator> module which will supercede
C<RTF::Document>.

=head1 METHODS

=head2 new

    $group = new RTF::Group LIST, PROPERTIES;

Creates a new group. If LIST is specified, it is appended to the group.
PROPERTIES are optional, and are used to set properties for the object.

By default, the C<subgroup> property is set.  This means that if the
group is appended to another group, it will be emitted (using the C<_rtf_list>
and C<as_string> methods) as a group within a group:

    $g1 = new RTF::Group(g1);
    $g2 = new RTF::Group(g2);
    $g1->append($g2);
    print $g1->as_string;       # emits '{g1{g2}}'

If we disable the C<subgroup> property, we get the following:

    $g1 = new RTF::Group(g1);
    $g2 = new RTF::Group(g2, {subgroup=>0});
    $g1->append($g2);
    print $g1->as_string;       # emits '{g1 g2}'

The C<escape> property enables automatic escaping of unescaped
curly brackets when a group is emitted as a string. (This property
is also enabled by default.)

The C<wrap> property is not used in this version.

Each property is also a method for getting or setting it's value. For
example,

    unless ($g2->subgroup)
    {
        $g2->subgroup(1);
    }

See the C<append> method for more details on how groups are handled.

=head2 append

    $group->append LIST;

Appends LIST to the group. LIST may be plain text, controls, other groups, or
references to a SCALAR or another LIST.

If LIST contains another RTF::Group, it will be embedded as a subgroup
(how this is handled is explained in the the documentation for the C<new>
method).

If LIST contains a reference to a SCALAR, the value it points to will be
emitted when the C<_rtf_list()> or C<_string> methods are called.

If LIST contains a reference to CODE, the value that code returns will
be emitted as if it were returned by C<_rtf_list()>. For instance,

    sub generator
    {
        my $arg = shift;
        return uc($arg);
    }

    $g1 = new RTF::Group(g1);
    $g1->append( \&generator, 'g2' );

    print $g1->as_string();            # emits '{g1 G2}'

Note that C<\&generator> must have one and only one argument, which is following item on the list. The argument is I<not> processed by C<RTF::Group>. (Versions of this module prior to 1.00 specified an array reference as the argument. This is not necessarily the case now.)

=head2 prepend

    $group->prepend LIST

Opposite of C<append>, in that the LIST is added before everything else in the
group. Use with caution.

=head2 as_string

    print $group->as_string();

Returns the group as a string that would appear in an RTF document. (The
deprecated C<string> method is an alias for C<as_string>.)

=head2 is_empty

    if ($group->is_empty) { ... }

Returns true if the group is empty, false if it contains something. Zero-length
strings are considered nothing.

=head2 _rtf_list

    @RTF = $group->_rtf_list LIST;

"Parses" LIST by dereferencing scalars, arrays or subgroups. If LIST is
not specified, parses group. (Although this may useful for parsers, it is
intended for internal use I<(read: private method)>.)

=head2 _list_as_string

    $output = $group->_list_as_string( LIST )

Converts the output of the C<_rtf_list()> method into a string. This is a
private method and may go away in future versions: use the C<as_string>
method instead.

=head2 _escape

    $atom = RTF::Group::_escape( SCALAR );

Does simple RTF escaping of brackets and 8-bit characters. It is also a private method.

=head2 escape_simple

    use RTF::Group qw( escape_simple  );

    $text = escape_simple( SCALAR );

Does simple escaping of characters not handled by _escape. Special characters
(such as tabs) are I<not> changed into their equivalent RTF control words.

=head2 check_params

This is a utility function used by some modules in the RTF-Generator
distribution (since RTF::Group is used by all modules). It may go away
in future versions.

=head1 CAVEATS

=head2 Incompatabilities with Previous Versions

This version is a rewrite. Some embarassingly wrongheaded code was changed.

Earlier versions of C<RTF::Group> specified that code references required an
array reference to follow as an argument. That is now not the case: while one
and only one argument is still required, it can be anything: a scalar, a scalar
reference, a hash reference, an array reference, etc.

=head2 Circular References

C<RTF::Group> cannot handle circular references. This version does not even check for them. Which means that

    $g1 = new RTF::Group();
    $g2 = new RTF::Group();

    $g1->append($g2);
    $g2->append($g1);

will cause I<bad things to happen>. Do not do this.

=head1 SEE ALSO

Microsoft Technical Support and Application Note, "Rich Text Format (RTF)
Specification and Sample Reader Program", Version 1.5.

=head1 FUTURE ENHANCEMENTS

I<Possibly> the ability to parse a stream into an C<RTF::Group> and some hooks to plug in a parser (so that the C<RTF::Parser> module will work nicely with this).

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 LICENSE

Copyright (c) 1999-2001 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


