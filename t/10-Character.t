# Tests for RTF::Character
# $Id: Character.t,v 1.1 2001/04/16 01:42:11 rrwo Exp $

require 5.005_62;

use Test;

BEGIN { plan tests => 2, todo => [ ] }

use strict;
use Carp;

use RTF::Group 1.20 qw( escape_simple );

ok(1);

use RTF::Character 1.01 qw( escape_text );

ok(1);
