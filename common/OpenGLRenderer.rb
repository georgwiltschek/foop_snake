require 'opengl'
require 'gl'
require 'mathn'
include Gl,Glu,Glut

require "#{File.dirname(__FILE__)}/../common/Shader"

LIGHT_POS = [100.0, 0.0, 100.0, 1.0]
RED = [0.8, 0.1, 0.0, 1.0]

ImageWidth = 20
ImageHeight = 20
$image = []
$texName = []

class Renderer
  
  def initialize
    @scale      = 8
    @w          = 640 / @scale
    @h          = 480 / @scale
    @mousePosition = [0,0]
    @numFrames = 0
    @startTime = SDL.getTicks
    
    # TODO dupe. put into config or somewhere else
    @colors = {
      :red    => {:c => 0xAD3333, :i => 0},
      :green  => {:c => 0x5CE65C, :i => 1},
      :yellow => {:c => 0xFFF666, :i => 2},
      :blue   => {:c => 0x3366FF, :i => 3},
      :purple => {:c => 0xFF70B8, :i => 4},
      :orange => {:c => 0xFFC266, :i => 5},
      :white  => {:c => 0xFFFFFF, :i => 6}
    }
    
    SDL.init(SDL::INIT_VIDEO)
    SDL.setGLAttr(SDL::GL_DOUBLEBUFFER,1)
    SDL.setVideoMode(@w * @scale, @h * @scale,32,SDL::OPENGL | SDL::GL_DOUBLEBUFFER | SDL::HWSURFACE)
    glViewport(0,0,@w * @scale, @h * @scale)
    @baseTime = SDL.getTicks


    
    GL.ClearColor(0.0, 0.0, 0.0, 0.0)
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    glOrtho(0, @w * @scale, @h * @scale, 0, 1000.0, -1000.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity()
    

    # texture stuff?
    # makeImage
    # makeStripeImage
    makeCheckImages
    
  	$texName = glGenTextures(1)
  	glBindTexture(GL_TEXTURE_2D, $texName[0])
  	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
  	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
  	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_NEAREST)
  	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_NEAREST)
  	glTexImage2D(GL_TEXTURE_2D, 0, 3, ImageWidth, ImageHeight, 0,
  		GL_RGB, GL_UNSIGNED_BYTE, $image.pack("C*"))
    # glEnable(GL_TEXTURE_2D)
    
    GL.Enable(GL::DEPTH_TEST)
    GL.Enable(GL::CULL_FACE)
    GL.Enable(GL::LIGHTING)
    GL.Lightfv(GL::LIGHT0, GL::POSITION, LIGHT_POS)
    GL.Enable(GL::LIGHT0)
    GL.ShadeModel(GL::SMOOTH)
    GL.Enable(GL::NORMALIZE)

		@log = Logger.new(STDOUT)

		@running = false
    @r = 0
    # and now... the shaders
    @shiny = Shader.new('shiny')
    @velvet = Shader.new('velvet')
    @hblur = Shader.new('hblur')
    @background = Shader.new('background')
    @trip = Shader.new('trip')
    
  end
  
  def fill_rect x,y,w,h,rgb

    red = (rgb >> 16) & 0xff;
    green = (rgb >> 8) & 0xff;
    blue = (rgb >> 0) & 0xff;

    red = red/255.0
    green = green/255.0
    blue = blue/255.0

    # puts "#{red} #{green} #{blue}"
    glColor red, green, blue
    # glBindTexture(GL_TEXTURE_2D, $texName[0])
    
    GL.Material(GL::FRONT, GL::AMBIENT_AND_DIFFUSE, [red, green, blue])
    GL.Material(GL::FRONT, GL::SPECULAR, [1.0, 1.0, 1.0]);
    GL.Material(GL::FRONT, GL::SHININESS, [50]);
    
    # GL.Material(GL::BACK, GL::AMBIENT_AND_DIFFUSE, [red, green, blue])
    # GL.Material(GL::BACK, GL::SPECULAR, [1.0, 1.0, 1.0]);
    # GL.Material(GL::BACK, GL::SHININESS, [50]);


    glBegin Gl::GL_POLYGON
    
      glNormal3f( 0.0,  0.0,  1.0)
      # glTexCoord2f(0.0, 1.0)
      # glColor3f( 1.0, 0.0, 0.0 )
    	glVertex2f( x, y )
      # glTexCoord2f(1.0, 1.0)
      # glColor3f( 0.0, 1.0, 0.0 )
    	glVertex2f( x,  y+h )
      # glTexCoord2f(1.0, 0.0)
      # glColor3f( 0.0, 0.0, 1.0 )
    	glVertex2f(  x+h,  y+h )
      # glTexCoord2f(0.0, 0.0)
      # glColor3f( 1.0, 0.0, 1.0 )
    	glVertex2f(  x+h, y )
  	glEnd
    
  end
  
  def draw snakes
  	realSec = (SDL.getTicks - @baseTime) / 1000.0

    # puts "draw #{@r} #{realSec}"
    GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
    # GL.MatrixMode(GL::PROJECTION)
    GL.LoadIdentity()
    
    #wohooo
    @r = @r + 1
    glPushMatrix

    glPushMatrix
      @background.apply
      @background.set_uniform1f("time",realSec)
      @background.set_uniform2f("resolution",@h * @scale, @w * @scale)
      @background.set_uniform2f("mouse",@mousePosition[0],@mousePosition[1])
      
      glTranslate 0,0,10
      fill_rect 0, 0, @h * @scale, @w * @scale, 0xFFFFFF
      @background.unload
    glPopMatrix
    
    @trip.apply
    @trip.set_uniform1f("time",realSec)
    @trip.set_uniform2f("resolution",@h * @scale, @w * @scale)
    @trip.set_uniform2f("mouse",@mousePosition[0],@mousePosition[1])
    

    snakes.each do |snake|
      first = true
      snake.get_tail.each do |t|
        
        if first then
          fill_rect t.x * @scale, t.y * @scale, @scale, @scale, @colors[t.color.to_sym][:c]
          first = false
        else
          draw_rect t.x * @scale, t.y * @scale, @scale, @scale, @colors[t.color.to_sym][:c]
        end
        
      end
    end
    
    @trip.unload
    
    # draw rules
    i = 0
    (@colors.sort_by {|k, v| v[:i]}).each do | color |
      fill_rect i * @scale, 0 * @scale, 8, 8, @colors[color[0].to_sym][:c]
      i += 1.5
    end
    
    
    glPopMatrix
    
    glRasterPos2d(10,20)
    "FPS: #{current_fps}".each_byte { |x| glutBitmapCharacter(GLUT_BITMAP_9_BY_15, x) }
    
    SDL.GL_swap_buffers
    @numFrames = @numFrames + 1
  end
  
  def current_fps
        return ((@numFrames/(SDL.getTicks - @startTime) )*1000).to_f
  end
    
  def draw_rect x, y, w, h, c
    
    glPushMatrix
    fill_rect x,y,w,h,c
    @trip.unload
    @background.apply
    glTranslate 0,0,-10
    fill_rect x+1,y+1,w-2,h-2,0x000000
    @background.unload
    @trip.apply
    glPopMatrix
  end
  
  # Stolen texture creation code
  def makeImage
  	for i in 0...ImageWidth
  		ti = 2.0*Math::PI*i/ImageWidth.to_f
  		for j in 0...ImageHeight
  			tj = 2.0*Math::PI*j/ImageHeight.to_f

  			$image[3*(ImageHeight*i+j)] =  127*(1.0+Math::sin(ti))
  			$image[3*(ImageHeight*i+j)+1] =  127*(1.0+Math::cos(2*tj))
  			$image[3*(ImageHeight*i+j)+2] =  127*(1.0+Math::cos(ti+tj))
  		end
  	end
  end

  def makeStripeImage
  	for j in (0..ImageWidth)
  		$image[4*j] = if (j<=4) then 255 else 0 end
  		$image[4*j+1] = if (j>4) then 255 else 0 end
  		$image[4*j+2] = 0
  		$image[4*j+3] = 255
  	end
  end

  def makeCheckImages
  	for i in (0..ImageHeight-1)
  		for j in (0..ImageWidth-1)
  			if ((i&0x8==0)!=(j&0x8==0)) then tmp = 1 else tmp=0 end
  			#c = ((((i&0x8)==0)^((j&0x8))==0))*255
  			c = tmp * 255
  			$image[i*ImageWidth*4+j*4+0] = c
  			$image[i*ImageWidth*4+j*4+1] = c
  			$image[i*ImageWidth*4+j*4+2] = c
  			$image[i*ImageWidth*4+j*4+3] = 255
  			#c = ((((i&0x10)==0)^((j&0x10))==0))*255
  			if ((i&0x10==0)!=(j&0x10==0)) then tmp = 1 else tmp=0 end
  			c = tmp * 255
  			$image[i*ImageWidth*4+j*4+0] = c
  			$image[i*ImageWidth*4+j*4+1] = 0
  			$image[i*ImageWidth*4+j*4+2] = 0
  			$image[i*ImageWidth*4+j*4+3] = 255
  		end
  	end
  end

end