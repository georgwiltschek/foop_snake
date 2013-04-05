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


class Client

	def initialize
		@scale = 8
		@w = 640 / @scale
		@h = 480 / @scale
    @mousePosition = [0,0]
    SDL.init SDL::INIT_VIDEO
        SDL.setGLAttr(SDL::GL_DOUBLEBUFFER,1)
    
    @screen   = SDL::set_video_mode @w * @scale, @h * @scale, 24, SDL::SWSURFACE
        @BGCOLOR = @screen.format.mapRGB 0, 0, 0
    

	end

	def handle_input
		event = SDL::Event2.poll

		case event

			when SDL::Event2::Quit
				@running = false
        
      # when SDL::Event2::MouseMotion
      #   @mousePosition =  [event.x, event.y]

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
		# TODO maybe check the SDL documentation, since the game tends
		# to stop redrawing after a while
    @screen.fill_rect 0, 0, @w * @scale, @h * @scale, @BGCOLOR
    
    snakes.each do |snake|
      snake.get_tail.each do |t|
        @screen.fill_rect t.x * @scale, t.y * @scale, 8, 8,t.color
      end
    end
    
    @screen.flip  
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

  def current_fps
    return ((@numFrames/(SDL.getTicks - @startTime) )*1000).to_f
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
    @numFrames = 0
    @startTime = SDL.getTicks
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
        @numFrames = @numFrames + 1
		end
	end
end

# create and run new client
c = Client.new
c.run