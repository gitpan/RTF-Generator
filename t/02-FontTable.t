# Tests for RTF::FontTable
# $Id: FontTable.t,v 1.1 2001/04/16 01:42:11 rrwo Exp $

require 5.005_62;

use Test;

BEGIN { plan tests => 3, todo => [ ] }

use strict;
use Carp;

use RTF::FontTable;
ok(1);

my $fonts = RTF::FontTable->new();
ok(1);

ok($fonts->count, 0);
