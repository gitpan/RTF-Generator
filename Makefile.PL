
# Makefile.PL for RTF::Generator&Co
# $Id: Makefile.PL,v 1.1.1.1 2001/03/30 23:39:58 rrwo Exp $

require 5.005_62;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => 'RTF::Generator',
    'PM' => {
       'Group.pm'        => '$(INST_LIBDIR)/Group.pm',
       'FontTable.pm'    => '$(INST_LIBDIR)/FontTable.pm',
       'ColorTable.pm'   => '$(INST_LIBDIR)/ColorTable.pm',
       'Character.pm'    => '$(INST_LIBDIR)/Character.pm',
       'StyleSheet.pm'   => '$(INST_LIBDIR)/StyleSheet.pm',
       'Paragraph.pm'    => '$(INST_LIBDIR)/Paragraph.pm',
       'Section.pm'      => '$(INST_LIBDIR)/Section.pm',
       'Generator.pm'    => '$(INST_LIBDIR)/Generator.pm',
     },
    'VERSION_FROM' => 'Generator.pm', # finds $VERSION
    'PREREQ_PM'		=> {
       'warnings::register'   => 0, # a good way to enforce Perl 5.6
       'Carp'                 => 0,
       'Convert::Units::Type' => 0,
#       'Graphics::ColorNames' => 0,
     },
  ($] ge '5.005') ? (
    'AUTHOR'   => 'Robert Rothenberg (rrwo@cpan.org)',
    'ABSTRACT' => 'Generate RTF::Documents',
  ) : (),
);
