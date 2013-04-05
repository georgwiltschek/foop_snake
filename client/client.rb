#! /usr/bin/ruby -w

require 'sdl'
require 'logger'
require 'rubygems'
require 'json'
require 'socket'
require 'opengl'
require 'gl'
require 'mathn'
include Gl,Glu,Glut


require "#{File.dirname(__FILE__)}/../common/Snake"
require "#{File.dirname(__FILE__)}/../common/Shader"

LIGHT_POS = [100.0, 0.0, 100.0, 1.0]
RED = [0.8, 0.1, 0.0, 1.0]

ImageWidth = 20
ImageHeight = 20
$image = []
$texName = []

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

class Client

	def initialize
		@scale = 20
		@w = 640 / 8
		@h = 480 / 8

    # SDL.init SDL::INIT_VIDEO
    #     SDL.setGLAttr(SDL::GL_DOUBLEBUFFER,1)
    # 
    # @screen   = SDL::set_video_mode @w * @scale, @h * @scale, 24, SDL::OPENGL
    #     # @BGCOLOR = @screen.format.mapRGB 0, 0, 0
    
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
	end

	def handle_input
		event = SDL::Event2.poll

		case event

			when SDL::Event2::Quit
				@running = false

			when SDL::Event2::KeyDown

				case event.sym

					when SDL::Key::ESCAPE
						@running = false

					when SDL::Key::LEFT
						direction = :left

					when SDL::Key::RIGHT
						direction = :right

					when SDL::Key::UP
						direction = :up

					when SDL::Key::DOWN
						direction = :down

				@log.info "Key Event: #{event.sym} #{direction}"
				return direction

			end
			
		end

	end

	# draws all the snakes
	def draw snakes
    draw_opengl snakes
		# TODO maybe check the SDL documentation, since the game tends
		# to stop redrawing after a while
    # @screen.fill_rect 0, 0, @w * @scale, @h * @scale, @BGCOLOR
    # 
    # snakes.each do |snake|
    #   snake.get_tail.each do |t|
    #     @screen.fill_rect t.x * @scale, t.y * @scale, 8, 8,t.color
    #   end
    # end
    # 
    # @screen.flip  
	end
  
  def gl_fill_rect x,y,w,h,rgb

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
  
  def draw_opengl snakes
  	realSec = (SDL.getTicks - @baseTime) / 1000.0

    puts "draw #{@r} #{realSec}"
    GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
    # GL.MatrixMode(GL::PROJECTION)
    GL.LoadIdentity()
    # perspective(projectionmatrix, 45.0, 1.0, 0.1, 100.0)
    # gl_fill_rect 0,0,100,100, 0
    
    #wohooo
    @r = @r + 1
    glPushMatrix
    # glRotate @r, 0.0, 1.0, 0.0
    glPushMatrix
      @background.apply
      @background.set_uniform1f("time",realSec)
      @background.set_uniform2f("resolution",@h * @scale, @w * @scale)
      @background.set_uniform2f("mouse",0,0)
      
      glTranslate 0,0,10
      gl_fill_rect 0, 0, @h * @scale, @w * @scale, 0xFFFFFF
      @background.unload
    glPopMatrix
    # @hblur.apply
    # @shiny.apply
    # @velvet.apply
    snakes.each do |snake|
      snake.get_tail.each do |t|
        gl_fill_rect t.x * @scale, t.y * @scale, @scale, @scale,t.color
      end
    end
    
    glPopMatrix
    
    SDL.GL_swap_buffers
  end

  def connect_to_server
    @socket = TCPSocket.open("localhost", 9876)
  end
  
  def send_direction(direction)
    package = {"direction"  => direction}
    jsonPackage = JSON.dump(package)
    # p package
    p jsonPackage
    @socket.puts(jsonPackage)
  end
  
  def get_update
    line = @socket.gets.chop
    die "connection lost" if !line
    
    json = JSON.parse(line)
    # p json
    
    update_snakes json
  end

  def update_snakes update
    update.each do |snake|
      # p snake
      @snakes.select { |s| snake["name"] == s.get_name}.map { |ss| ss.update_tail snake["tail"]}
    end
  end

	def run
		@snakes = Array.new

		@snakes.push(Snake.new(8, 8, 123456, "Clyde", nil, @w, @h))  
		@snakes.push(Snake.new(40, 40, 98765,   "Pinky",  nil, @w, @h))
		@snakes.push(Snake.new(15, 15, 8000000, "Blinky", nil, @w, @h))
		@snakes.push(Snake.new(60, 15, 4324324, "Inky",   nil, @w, @h))

    die "can't connect to server" unless connect_to_server

    	changed = false

		@running = true
		lastdir = nil

		t = Time.now
		# main loop
		while @running
			d = (Time.now - t) * 1000 # elapsed time since last tick

			# this should be sent to the server
			direction = handle_input
			if direction != nil then
				changed = lastdir != direction
				lastdir = dir = direction
			end

			# tick
			if (d > 10) then
				t = Time.now
		        # @log.info "tick"

		        if changed
		        	send_direction(dir)
		        	changed = false
		        end

		    	get_update
	    	end
					
		    draw(@snakes)
		end
	end
end

# create and run new client
c = Client.new
c.run