#! /usr/bin/ruby -w

require 'sdl'
require 'logger'
require 'rubygems'
require 'json'
require 'socket'

require "#{File.dirname(__FILE__)}/../common/Snake"

class Client

	# constructor
	def initialize(ip, port)
		@scale      = 8
		@w          = 640 / @scale
		@h          = 480 / @scale
		@running    = false
		@log        = Logger.new(STDOUT)
		@serverip   = ip
		@serverport = port

		SDL.init SDL::INIT_VIDEO
		
		@screen  = SDL::set_video_mode @w * @scale, @h * @scale, 24, SDL::SWSURFACE
		@BGCOLOR = @screen.format.mapRGB 0, 0, 0
	end

	def handle_input
		event = SDL::Event2.poll

		case event
			# quit
			when SDL::Event2::Quit
				@running = false
				return
				
			# other keys
			when SDL::Event2::KeyDown
				case event.sym
					# quit via escape
					when SDL::Key::ESCAPE
						@running = false
						return

					# directions
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
		@screen.fill_rect 0, 0, @w * @scale, @h * @scale, @BGCOLOR

		snakes.each do |snake|
			snake.get_tail.each do |t|
				@screen.fill_rect t.x * @scale, t.y * @scale, 8, 8,t.color
			end
		end

		@screen.flip    
	end

	def connect_to_server
		@socket = TCPSocket.open(@serverip, @serverport)
	end
  
  	# send the direction to the sierver
	def send_direction(direction)
		package = {"direction"  => direction}
		jsonPackage = JSON.dump(package)
		p jsonPackage
		@socket.puts(jsonPackage)
	end
  
	# gets game state from server
	def get_update
		line = @socket.gets.chop

		die "connection lost" if !line
		
		update_snakes JSON.parse(line)
	end

	# update each snake
	def update_snakes update
		update.each do |snake|
			@snakes.select { |s| snake["name"] == s.get_name}.map { |ss| ss.update_tail snake["tail"]}
		end
	end

	def run
		changed  = false
		@snakes  = Array.new
		@running = true
		lastdir  = nil

		@snakes.push(Snake.new(8,  8,  123456,  "Clyde",  nil, @w, @h))  
		@snakes.push(Snake.new(40, 40, 98765,   "Pinky",  nil, @w, @h))
		@snakes.push(Snake.new(15, 15, 8000000, "Blinky", nil, @w, @h))
		@snakes.push(Snake.new(60, 15, 4324324, "Inky",   nil, @w, @h))

		die "can't connect to server" unless connect_to_server

		t = Time.now

		# main game loop
		while @running
			d = (Time.now - t) * 1000 # elapsed time since last tick

			# get direction changes from input handler
			direction = handle_input
			if direction != nil then
				changed = lastdir != direction
				lastdir = dir = direction
			end

			# tick
			if (d > 10) then
				t = Time.now

				# send direction if changed
				if changed
					send_direction(dir)
					changed = false
				end

				# get updated gamestate from server
				get_update
			end

			draw(@snakes)
		end
	end
end

# create and run new client
c = Client.new("localhost", 9876)
c.run