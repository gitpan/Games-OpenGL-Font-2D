
# Games-OpenGL-Font-2D - load/render 2d fonts to via OpenGL

package Games::OpenGL::Font::2D;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use SDL::OpenGL;
use SDL::Surface;
use vars qw/@ISA $VERSION/;
@ISA = qw/Exporter/;

$VERSION = '0.03';

##############################################################################
# methods

sub new
  {
  # create a new instance of a font
  my $class = shift;

  my $self = { };
  bless $self, $class;
  
  my $args = $_[0];
  $args = { @_ } unless ref $args eq 'HASH';

  $self->{file} = $args->{file} || '';
  $self->{color} = $args->{color} || [ 1,1,1 ];
  $self->{alpha} = $args->{alpha} || 1;
  $self->{set} = 0;
  $self->{char_width} = int(abs($args->{char_width} || 16));
  $self->{char_height} = int(abs($args->{char_height} || 16));
  $self->{spacing_x} = int($args->{spacing_x} || $self->{char_width});
  $self->{spacing_y} = int($args->{spacing_y} || 0);
  $self->{transparent} = 1;
  $self->{width} = 640;
  $self->{height} = 480;
  $self->{zoom_x} = abs($args->{zoom_x} || 1);
  $self->{zoom_y} = abs($args->{zoom_y} || 1);
  $self->{chars} = int(abs($args->{chars} || (256-32)));
  $self->{chars_per_line} = int(abs($args->{chars_per_line} || 32));
  
  $self->_read_font($self->{file});
  
  # Create the display lists
  $self->{base} = glGenLists( $self->{chars} );

  $self->_build_font();
  $self;
  }

sub _read_font
  {
  my $self = shift;

  # load the file as SDL::Surface into memory
  my $font = SDL::Surface->new( -name => $self->{file} );

  # create one texture and bind it to our object's member 'texture'
  $self->{texture} = glGenTextures(1)->[0];
  glBindTexture( GL_TEXTURE_2D, $self->{texture} );

  # Select nearest filtering
  glTexParameter( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
  glTexParameter( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

  # generate the OpenGL texture
  glTexImage2D(
    GL_TEXTURE_2D, 0, 3, $font->width(), $font->height(), 0, GL_BGR,
    GL_UNSIGNED_BYTE, $font->pixels() );

  $self->{texture_width} = $font->width();
  $self->{texture_height} = $font->height();

  # $font will go out of scope and thus freed at the end of this sub
  }

sub _build_font
  {
  my $self = shift;

  # select our font texture
  glBindTexture( GL_TEXTURE_2D, $self->{texture} );

  my $cw = $self->{char_width};
  my $ch = $self->{char_height};
  my $w = int($cw * $self->{zoom_x});
  my $h = int($ch * $self->{zoom_y});
  # calculate w/h of a char in 0..1 space
  my $cw = $cw/$self->{texture_width};
  my $ch = $ch/$self->{texture_height};
  my $cx = 0; my $cy = 0;
  my $c = 0;
  # loop through all characters
  for my $loop (1 .. $self->{chars})
    {
    # start building a list
    glNewList( $self->{base} + $loop - 1, GL_COMPILE ); 
    # Use A Quad For Each Character
    glBegin( GL_QUADS );

      # Bottom Left 
      glTexCoord( $cx, $cy + $ch);	# was: 0.0625
      glVertex( 0, 0 );

      # Bottom Right
      glTexCoord( $cx + $cw, $cy + $ch);
      glVertex( $w, 0 );

      # Top Right
      glTexCoord( $cx + $cw, $cy);
      glVertex( $w, $h );

      # Top Left 
      glTexCoord( $cx , $cy);
      glVertex( 0, $h );

    glEnd();

    # move to next character
    glTranslate( $self->{spacing_x} * $self->{zoom_x}, 
                 $self->{spacing_y} * $self->{zoom_y}, 0 );
    glEndList();
    
    # X and Y position of next char
    $cx += $cw;
    if (++$c >= $self->{chars_per_line})
      {
      $c = 0; $cx = 0; $cy += $ch;
      }


    }
  }

sub pre_output
  {
  my $self = shift;

  # Select our texture
  glBindTexture( GL_TEXTURE_2D, $self->{texture} );

  # Disable/Enable flags, unless they are already in the right state
  glDisable( GL_DEPTH_TEST );
  glDepthMask(GL_FALSE);	# disable writing to depth buffer
  glEnable( GL_TEXTURE_2D );
  
  glEnable( GL_BLEND );
  # Select The Type Of Blending
  if ($self->{transparent})
    {
    glBlendFunc(GL_SRC_ALPHA,GL_ONE);
    }
  else
    {
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    }

  # Select The Projection Matrix
  glMatrixMode( GL_PROJECTION );
  # Store The Projection Matrix
  glPushMatrix();
  # Reset The Projection Matrix
  glLoadIdentity();

  # Set Up An Ortho Screen 
  #        left, right,       bottom, top,        near, far
  glOrtho( 0, $self->{width}, 0, $self->{height}, -1, 1 );
  
  # Select The Modelview Matrix
  glMatrixMode( GL_MODELVIEW );
  # Store the Modelview Matrix
  glPushMatrix();
  # Reset The Modelview Matrix
  glLoadIdentity();
  }

sub output
  {
  # Output the given string at the coordinates
  my ($self,$x,$y,$string,$color,$alpha) = @_;

  # Reset The Modelview Matrix
  glLoadIdentity();

  # Position The Text (0,0 is Bottom Left)
  glTranslate( $x, $y, 0 );

  # set color and alpha value
  $color = $self->{color} unless defined $color;
  $alpha = $self->{alpha} unless defined $alpha;
  if (defined $color)
    {
    # if not, caller wanted to set color by herself
    if (defined $alpha)
      {
      glColor (@$color,$alpha);
      }
    else
      {
      glColor (@$color,1);
      }
    }

  # Choose The Font Set (0 or 1) (-32 because our lists start at 0, and space
  # has an ASCII value of 32 and is the first existing character)
  glListBase( $self->{base} - 32 + ( 128 * $self->{set} ) );

  # write the text to the screen
  #my @chars = map { ord($_) } split //, $string;
  # glCallLists( @chars); # , $chars[-1]);

  # much faster
  glCallListsScalar( $string );

  }

sub post_output
  {
  # Reset the OpenGL stuff

  # Select The Projection Matrix
  glMatrixMode( GL_PROJECTION );
  # Restore The Old Projection Matrix 
  glPopMatrix();

  # Select the Modelview Matrix 
  glMatrixMode( GL_MODELVIEW );
  # Restore the Old Projection Matrix
  glPopMatrix();

  # Caller must re-enable or re-disable flags if he wishes
  }

sub screen_width
  {
  my $self = shift;

  $self->{width} = shift if @_ > 0;
  $self->{width};
  }

sub screen_height
  {
  my $self = shift;

  $self->{height} = shift if @_ > 0;
  $self->{height};
  }

sub color
  {
  my $self = shift;

  $self->{color} = shift if @_ > 0;
  $self->{color};
  }

sub transparent
  {
  my $self = shift;

  $self->{transparent} = shift if @_ > 0;
  $self->{transparent};
  }

sub set
  {
  my $self = shift;

  $self->{set} = $_[0] ? 1 : 0 if @_ > 0;
  $self->{set};
  }

sub alpha
  {
  my $self = shift;

  $self->{alpha} = shift if @_ > 0;
  $self->{alpha};
  }

sub spacing_x
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{spacing_x} = shift;
    $self->_build_font();
    }
  $self->{spacing_x};
  }

sub spacing_y
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{spacing_y} = shift;
    $self->_build_font();
    }
  $self->{spacing_y};
  }

sub spacing
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{spacing_x} = shift;
    $self->{spacing_y} = shift;
    $self->_build_font();
    }
  ($self->{spacing_x}, $self->{spacing_y});
  }

sub zoom
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{zoom_x} = shift;
    $self->{zoom_y} = shift;
    $self->_build_font();
    }
  ($self->{zoom_x}, $self->{zoom_y});
  }

sub copy
  {
  my $self = shift;

  my $class = ref($self);
  my $new = {};
  foreach my $k (keys %$self)
    {
    $new->{$k} = $self->{$k};
    }
  $new->{base} = glGenLists (256);	# get the new font 256 new lists
  bless $new, $class;
  $new->_build_font();
  $new;
  }

1;

__END__

=pod

=head1 NAME

Games::OpenGL::Font::2D - load/render 2D colored bitmap fonts via OpenGL

=head1 SYNOPSIS

	use Games::OpenGL::Font::2D;

	my $font = Games::OpenGL::Font::2D->new( 
          file => 'font.bmp' );

	use SDL::App::FPS;


	my $app = SDL::App::FPS->new( ... );

	# don't forget to change these on resize events!
	$font->screen_width( $app->width() );
	$font->screen_height( $app->width() );

	$font->pre_output();		# setup rendering for font
	
	$font->color( [ 0,1,0] );	# yellow
	$font->alpha( 0.8 );		# nearly opaque

	# half-transparent, red
	$font->output (100,100, 'Hello OpenGL!', [ 1,0,0], 0.5 );
	# using the $font's color and alpha
	$font->output (100,200, 'Hello OpenGL!' );
	
	$font->transparent( 1 );	# render font background transparent
	$font->set( 1 );		# choose alternative font set
	
	$font->spacing_y( 16 );		# render vertical (costly rebuild!)
	$font->spacing_x( 0 );		# (costly rebuild!)
	$font->output (100,200, 'Hello OpenGL!' );

	$font->post_output();		# if wanted, you can reset OpenGL

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

This package let's you load and render colored bitmap fonts via OpenGL.

=head1 METHODS

=over 2

=item new()

	my $font = OpenGL::Font::2D->new( $args );

Load a model into memory and return an object reference. C<$args> is a hash
ref containing the following keys:

	file		filename of font bitmap
	transparent	if true, render font background transparent (e.g.
			don't render it at all)
	set		choose font 0 or 1 (each set has 128 letters)
	color		color of output text as array ref [r,g,b]
	alpha		blend font over background for semitransparent
	char_width	Width of each char on the texture
	char_height	Width of each char on the texture
  	chars		Number of characters on font-texture
	spacing_x	Spacing in X direction after each char
	spacing_y	Spacing in Y direction after each char

Example:

	my $font = OpenGL::Font::2D->new( file => 'data/courier.txt',
		char_width => 11, char_height => 21, 
		zoom_x => 2, zoom_y => 1,
		spacing_x => 21, spacing_y => 0,
	);

=item output()

	$font->output ($x,$y, $string, $color, $alpha, $set, $transparent);

Output the string C<$string> at the coordinates $x and $y. 0,0 is at the
lower left corner of the screen.

C<$color>, C<$alpha>, C<$set> and C<$transparent> are optional and if omitted
or given as undef, will be taken from the font's internal values, which can
be given at new() or modified with the routines below.

=item set()

	my $set = $font->set();
	$font->set(1);

Get/set the font set to use. Each set has 128 characters.

=item transparent()

	$model->frames();

Get/set the font's transparent flag. Setting it to true renders the font
background as transparent.

=item color()

        $rgb = $font->color();		# [$r,$g, $b ]
        $font->color(1,0.1,0.8);	# set RGB
        $font->color(undef);		# no color

Sets the color, that will be set to render the font. No color means the caller
can set the color before calling L<output()>.

=item alpha()

        $a = $font->alpha();		# $a
        $font->color(0.8);		# set A
        $font->alpha(undef);		# set's it to 1.0 (seems an OpenGL
					# specific set because
					# glColor($r,$g,$b) also sets $a == 1

Sets the alpha value of the rendered output.

=item spacing_x()

	$x = $font->spacing_x();
	$font->spacing_x( $new_width );

Get/set the width of each character. Default is 10. This is costly, since it
needs to rebuild the font. See also L<spacing_y()> and L<spacing()>.

=item spacing_y()

	$x = $font->spacing_y();
	$font->spacing_y( $new_height );

Get/set the width of each character. Default is 0. This is costly, since it
needs to rebuild the font. See also L<spacing_x()> and L<spacing()>.

=item spacing()

	($x,$y) = $font->spacing();
	$font->spacing( $new_width, $new_height );

Get/set the width and height of each character. Default is 10 and 0. This is
costly, since it needs to rebuild the font. If you need to render vertical
texts, you can use this:

	$font->spacing(0,16);

However, for mixing vertical and horizontal text, better create two font's
objects by cloning an existing:
	
	$font_hor = OpenGL::Font::2D->new( ... );
	$font_ver = $font_hor->copy();
	$font_ver->spacing(0,16);

The two font objects will thus share the texture, and you don't need to
rebuild the font by setting the spacing for each text you want to render.

See also L<spacing_x()> and L<spacing_y()>.

=item zoom()

	($x,$y) = $font->zoom();
	$font->zoom( $new_width, $new_height );

Get/set the zoom factor for each character. Default is 1 and 1. This is
costly, since it needs to rebuild the font. See L<spacing()> on how to
avoid the font-rebuilding for each text output.

=item pre_output()

	$font->pre_output();

Sets up OpenGL so that the font can be rendered on the screen. 

=item ppost_output()

	$font->post_output();

Resets some OpenGL stuff after rendering. If you reset OpenGL for the next
frame anyway, or use a different font's pre_ouput() afterwards, you can skip
this.

=back

=head1 KNOWN BUGS

None yet.

=head1 AUTHORS

(c) 2003 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::3D>, L<SDL:App::FPS>, and L<SDL::OpenGL>.

=cut

