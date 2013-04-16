require 'opengl'
require 'gl'
require 'mathn'
require "./common/Hash"
require "./common/Shader"

include Gl, Glu, Glut

LIGHT_POS = [100.0, 0.0, 100.0, 1.0]
RED = [0.8, 0.1, 0.0, 1.0]

ImageWidth = 20
ImageHeight = 20
$image = []
$texName = []

# not so simple opengl based renderer. with shaders and stuff! :)
class Renderer
  attr_accessor :colors

  def initialize
    @scale  = Settings.scale
    @w      = Settings.w
    @h      = Settings.h
    @width = @w * @scale
    @height = @h * @scale
    @colors = Settings.colors
    @log    = Logger.new(STDOUT)
    @doBloom = true
    @doBlur  = true
    @doTunnelblick  = true

    @mousePosition = [0,0]

    SDL.init(SDL::INIT_VIDEO)
    SDL.setGLAttr(SDL::GL_DOUBLEBUFFER,1)
    SDL.setVideoMode(@w * @scale, @h * @scale,32,SDL::OPENGL | SDL::GL_DOUBLEBUFFER | SDL::HWSURFACE)
    glViewport(0,0,@w * @scale, @h * @scale)

    @numFrames = 0
    @baseTime = SDL.getTicks
    @log.info "startTime #{@baseTime}"

    glutInit()
    GL.ClearColor(0.0, 0.0, 0.0, 0.0)

    # texture stuff?
    # makeImage
    # makeStripeImage
    #     makeCheckImages
    # glPixelStore(GL_UNPACK_ALIGNMENT, 1)
    # 
    #     $texName = glGenTextures(1)
    #     glBindTexture(GL_TEXTURE_2D, $texName[0])
    #     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
    #     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
    #     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_NEAREST)
    #     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_NEAREST)
    #     glTexImage2D(GL_TEXTURE_2D, 0, 3, ImageWidth, ImageHeight, 0,
    #     GL_RGB, GL_UNSIGNED_BYTE, $image.pack("C*"))
    
    GL.Enable(GL::DEPTH_TEST)
    GL.Enable(GL::CULL_FACE)
    GL.Enable(GL::LIGHTING)
    GL.Lightfv(GL::LIGHT0, GL::POSITION, LIGHT_POS)
    GL.Enable(GL::LIGHT0)
    GL.ShadeModel(GL::SMOOTH)
    GL.Enable(GL::NORMALIZE)

    @running = false
    @r = 0
    # and now... the shaders
    # @shiny = Shader.new('shiny')
    # @velvet = Shader.new('velvet')
    # @hblur = Shader.new('hblur')
    @backgroundList = [Shader.new('balls'), Shader.new('space'), Shader.new('background')]
    @background = @backgroundList.first
    @trip = Shader.new('trip')
    
    @blur = [Shader.new('vblur'), Shader.new('hblur')]
    @bloom = Shader.new('bloom')
    @tunnelblick = Shader.new('tunnelblick')
    
    create_fbo_texture
    create_fbo
  end
  
  def update_colors colors
    @colors = Hash.transform_keys_to_symbols(colors)
  end

  def fill_rect x,y,w,h,rgb
    red = (rgb >> 16) & 0xff;
    green = (rgb >> 8) & 0xff;
    blue = (rgb >> 0) & 0xff;

    red = red/255.0
    green = green/255.0
    blue = blue/255.0
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
    @currentSnakes = snakes
    # debug_input_listener
    
    @realSec = (SDL.getTicks - @baseTime) / 1000.0

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, @w * @scale, @h * @scale, 0, 1000.0, -1000.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity()
    GL.LoadIdentity()
    
    glBindFramebufferEXT(GL::FRAMEBUFFER_EXT, @frameBuffer)
    # Render into FrameBuffer
    GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)

    #wohooo
    @r = @r + 1
    glPushMatrix

    glPushMatrix
      @background = @backgroundList[(@numFrames%300)/100]

      @background.apply
      @background.set_uniform1f("time",@realSec)
      @background.set_uniform2f("resolution",@h * @scale, @w * @scale)
      @background.set_uniform2f("mouse",@mousePosition[0],@mousePosition[1])
      
      glTranslate 0,0,10
      fill_rect 0, 0, @h * @scale, @w * @scale, 0xFFFFFF
      @background.unload
    glPopMatrix
    

    draw_snakes
    
    # draw rules
    i = 0
    (@colors.sort_by {|k, v| v[:i]}).each do | color |
      fill_rect i * @scale, 0 * @scale, @scale, @scale, @colors[color[0].to_sym][:c]
      i += 1.5
    end
    
    glPopMatrix
    # Finished rendering into FrameBuffer
    
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    glOrtho(0, @width , @height , 0, 1000.0, -1000.0)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    
    glColor 1,1,1,1
    glDisable(GL::LIGHTING)
    glEnable(GL::TEXTURE_2D)
    
    
    # if @doTunnelblick then
    #   @tunnelblick.apply
    #   render_fbo true
    #   @tunnelblick.unload
    #   return
    # end
    
    if @doBlur then
      @blur[0].apply
      @blur[0].set_uniform1f("rt_w", @width.to_f)
      @blur[0].set_uniform1f("rt_h", @height.to_f)
      @blur[0].set_uniform1f("vx_offset", 0.5 )
      render_fbo
      @blur[0].unload
      
      @blur[1].apply
      @blur[1].set_uniform1f("rt_w", @width.to_f)
      @blur[1].set_uniform1f("rt_h", @height.to_f)
      @blur[1].set_uniform1f("vx_offset", 0.5 )
      render_fbo
      @blur[1].unload
    end
      
    if @doBloom then
      @bloom.apply
      render_fbo    
      @bloom.unload
    end
    
    render_fbo true
    
    glEnable(GL::LIGHTING)
    glDisable(GL::TEXTURE_2D)

    
    # puts  "FPS: #{current_fps}"
    
    @numFrames = @numFrames + 1
  end
  
  def draw_snakes withoutShader=false
    if !withoutShader then
      @trip.apply
      @trip.set_uniform1f("time",@realSec)
      @trip.set_uniform2f("resolution",@h * @scale, @w * @scale)
      @trip.set_uniform2f("mouse",@mousePosition[0],@mousePosition[1])
    end
    
    @currentSnakes.each do |snake|
      first = true
      snake.get_tail.each do |t|
        if first then
          fill_rect t.x * @scale, t.y * @scale, @scale - 1, @scale - 1, @colors[t.color.to_sym][:c]
          first = false
        else
          draw_rect t.x * @scale, t.y * @scale, @scale - 1, @scale - 1, @colors[t.color.to_sym][:c]
        end
      end
    end
    
    @trip.unload if !withoutShader
  end
  
  def render_fbo isFinal=false
    if isFinal then
      glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0); # unbind
      glBindTexture(GL_TEXTURE_2D, @texture);
      glGenerateMipmapEXT(GL_TEXTURE_2D);
      glBindTexture(GL_TEXTURE_2D, 0);
      glViewport(0, 0, @width, @height);
    
      glBindTexture(GL_TEXTURE_2D, @texture);    
    else
      # we have to render into a new texture
      previousTexture = @texture
      create_fbo_texture
      glFramebufferTexture2DEXT(GL::FRAMEBUFFER_EXT, GL::COLOR_ATTACHMENT0_EXT, GL::TEXTURE_2D, @texture, 0)
      glBindTexture(GL_TEXTURE_2D, previousTexture);    
    end
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glBegin(GL_QUADS);
        glTexCoord2f(0,1);   glVertex2f(0,0);
        glTexCoord2f(0,0);   glVertex2f(0,@height);
        glTexCoord2f(1,0);   glVertex2f(@width,@height);
        glTexCoord2f(1,1);   glVertex2f(@width,0);
    glEnd();
    
    if isFinal then
      glEnable(GL::LIGHTING)
      glDisable(GL::TEXTURE_2D)
      draw_snakes
      
      glRasterPos2d(10,20)
      "FPS: #{current_fps}".each_byte { |x| glutBitmapCharacter(GLUT_BITMAP_9_BY_15, x) }
    end
    
    glDeleteTextures(previousTexture) if !isFinal
    SDL.GL_swap_buffers if isFinal
  end
  
  def current_fps
    return ((@numFrames/(SDL.getTicks - @baseTime) )*1000).to_f
  end
    
  def create_fbo
    @frameBuffer = glGenFramebuffersEXT(1)[0]
    glBindFramebufferEXT(GL::FRAMEBUFFER_EXT, @frameBuffer)
    @renderBuffer = glGenRenderbuffersEXT(1)[0]
    glBindRenderbufferEXT(GL::RENDERBUFFER_EXT,@renderBuffer)
    glRenderbufferStorageEXT(GL::RENDERBUFFER_EXT, GL::DEPTH_COMPONENT, @width, @height)
    glBindRenderbufferEXT(GL::RENDERBUFFER_EXT,0)
 
    glFramebufferTexture2DEXT(GL::FRAMEBUFFER_EXT, GL::COLOR_ATTACHMENT0_EXT, GL::TEXTURE_2D, @texture, 0)
    
    glFramebufferRenderbufferEXT(GL::FRAMEBUFFER_EXT, GL::DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, @renderBuffer)
    
    fbo_status
    glBindFramebufferEXT(GL::FRAMEBUFFER_EXT, 0)
    
  end
  
  def create_fbo_texture
    @texture = glGenTextures(1)[0]
    glBindTexture(GL::TEXTURE_2D, @texture)
    
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, 1); #GL_TRUE
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, @width, @height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil); # place multisampling here too!
    glBindTexture(GL_TEXTURE_2D, 0);
  end
    
  
  def fbo_status
    stat = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)
    # printf("FBO status: %04X\n", stat)
    return if (stat==0 || stat == GL_FRAMEBUFFER_COMPLETE_EXT)
    printf("FBO status: %04X\n", stat)
    exit(0)
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
  
  def debug_input_listener
      event = SDL::Event2.poll

      case event
        # quit
        when SDL::Event2::Quit
          @running = false
          return

        # other keys
        when SDL::Event2::KeyDown
                      puts event.sym
          case event.sym
          when SDL::Key::K1
              @doBloom = !@doBloom
              puts "bloom #{@doBloom}"
          when SDL::Key::K2
              @doBlur = !@doBlur
              puts "blur #{@doBlur}"
          when SDL::Key::K3
              @doTunnelblick = !@doTunnelblick
              puts "tunnelblick #{@doTunnelblick}"
            

        end
      end
  end
  
  # Stolen texture creation code
  def makeImage
    for i in 0...@width
      ti = 2.0*Math::PI*i/ImageWidth.to_f
      for j in 0...@height
        tj = 2.0*Math::PI*j/ImageHeight.to_f

        $image[3 * (@height * i + j)]    =  127*(1.0 + Math::sin(ti))
        $image[3 * (@height * i + j) +1] =  127*(1.0 + Math::cos(2*tj))
        $image[3 * (@height * i + j) +2] =  127*(1.0 + Math::cos(ti+tj))
      end
    end
  end

  def makeStripeImage
  	for j in (0..ImageWidth)
  		$image[4 * j]     = if (j <= 4)  then 255 else 0 end
  		$image[4 * j + 1] = if (j >  4)  then 255 else 0 end
  		$image[4 * j + 2] = 0
  		$image[4 * j + 3] = 255
  	end
  end

  def makeCheckImages
  	for i in (0..ImageHeight-1)
  		for j in (0..ImageWidth-1)
  			if ((i&0x8==0)!=(j&0x8==0)) then tmp = 1 else tmp=0 end
  			#c = ((((i&0x8)==0)^((j&0x8))==0))*255
  			c = tmp * 255
  			$image[i * ImageWidth * 4 + j * 4 + 0] = c
  			$image[i * ImageWidth * 4 + j * 4 + 1] = c
  			$image[i * ImageWidth * 4 + j * 4 + 2] = c
  			$image[i * ImageWidth * 4 + j * 4 + 3] = 255
  			#c = ((((i&0x10)==0)^((j&0x10))==0))*255
  			if ((i&0x10==0)!=(j&0x10==0)) then tmp = 1 else tmp=0 end
  			c = tmp * 255
  			$image[i * ImageWidth * 4 + j * 4 + 0] = c
  			$image[i * ImageWidth * 4 + j * 4 + 1] = 0
  			$image[i * ImageWidth * 4 + j * 4 + 2] = 0
  			$image[i * ImageWidth * 4 + j * 4 + 3] = 255
  		end
  	end
  end
end
