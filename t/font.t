#!/usr/bin/perl -w

use Test::More tests => 6;
use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../blib/lib';
  unshift @INC, '../blib/arch';
  unshift @INC, '.';
  chdir 't' if -d 't';
  use_ok ('Games::OpenGL::Font::2D');
  }

can_ok ('Games::OpenGL::Font::2D', qw/ 
  new output
  color alpha transparent set
  spacing spacing_x spacing_y
  copy zoom
  pre_output
  post_output
  /);

my $font = Games::OpenGL::Font::2D->new (
  file => 'font.bmp', color => [ 0,1,0 ], alpha => 0.5
  );

is (ref($font), 'Games::OpenGL::Font::2D', 'new worked');

is (join(',',@{$font->color()}), '0,1,0', 'color');
is ($font->alpha(), '0.5', 'alpha');

my $copy = $font->copy();

is (ref($copy), 'Games::OpenGL::Font::2D', 'copy worked');
 
