# Tests and hacking for RTF::Generator
# $Id: Generator.t,v 1.1 2001/04/16 01:42:11 rrwo Exp $

require 5.005_62;

use Test;

BEGIN { plan tests => 1, todo => [ ] }

use RTF::Generator 1.00;

ok(1);

exit 0;

my $rtf = RTF::Generator->new();

$rtf->set_charset('ansi');
# $rtf->set_version(1);

my $cBlue = $rtf->add_color( 0, 0, 128);

my $fArial = $rtf->add_font( "Arial", { FontFamily=>'swiss' } );

open FH, ">foo.rtf";

$rtf->add_text(
    {
      VerticalAlign=>'bottom',
      PageHeight => '3in',
      PageWidth => '5in',
    },
  paragraph(
    {
      Bold => 1,
      Caps => 1,
    },
    "This is a test",
    line_break(),
    "Another Line"
  )
);

my $fTimes = $rtf->add_font( "Times New Roman", { FontFamily=>'roman' } );

$rtf->set_default_font( $fTimes );

$rtf->add_text(
  paragraph(
    {
      Align => 'right',
      Font  => $fArial,
      Bold  => 0,
    },
    "More"
  )
);



print FH $rtf->as_string;

# print STDERR $rtf->as_string;

close FH;
