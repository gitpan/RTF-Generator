# Tests for RTF::StyleSheet
# $Id: StyleSheet.t,v 1.1 2001/04/16 01:42:11 rrwo Exp $

require 5.005_62;

use Test;

BEGIN { plan tests => 4, todo => [ ] }

use strict;
use Carp;

use RTF::StyleSheet;
ok(1);

my $style = RTF::StyleSheet->new();
ok(1);

my $fonts = $style->get_fonttable();
ok(1);

my $color = $style->get_colortable;
ok(1);
