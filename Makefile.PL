use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Games::OpenGL::Font::2D',
    'VERSION_FROM'	=> 'lib/Games/OpenGL/Font/2D.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			SDL => 'v1.20.3', # http://bloodgate.com/perl/sdl/
			}, # e.g., Module::Name => 1.1
    'LIBS'		=> [ ], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);
