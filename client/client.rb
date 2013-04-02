#! /usr/bin/ruby -w

require 'sdl'
require 'logger'
require 'rubygems'
require 'json'
require 'socket'
require 'opengl'
require 'gl'
include Gl,Glu,Glut


require "#{File.dirname(__FILE__)}/../common/Snake"

class Client

	def initialize
		@scale = 8
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
    
    GL.ClearColor(0.0, 1.0, 0.0, 0.0)
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    glOrtho(0, @w * @scale, @h * @scale, 0, 1, -1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity()
    
    # GL.ClearDepth(1.0)
    

		@log = Logger.new(STDOUT)

		@running = false
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
  
  def gl_fill_rect x,y,w,h,color
    glColor 1,0,0
    glBegin Gl::GL_POLYGON
    # glColor3f( 1.0, 0.0, 0.0 )
  	glVertex2f( x, y )
    # glColor3f( 0.0, 1.0, 0.0 )
  	glVertex2f( x,  y+h )
    # glColor3f( 0.0, 0.0, 1.0 )
  	glVertex2f(  x+h,  y+h )
    # glColor3f( 1.0, 0.0, 1.0 )
  	glVertex2f(  x+h, y )
  	glEnd
    
  end
  
  def draw_opengl snakes
    puts "draw"
    GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
    # GL.MatrixMode(GL::PROJECTION)
    GL.LoadIdentity()
    # perspective(projectionmatrix, 45.0, 1.0, 0.1, 100.0)
    # gl_fill_rect 0,0,100,100, 0
    
    snakes.each do |snake|
      snake.get_tail.each do |t|
        gl_fill_rect t.x * @scale, t.y * @scale, 8, 8,t.color
      end
    end
    
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