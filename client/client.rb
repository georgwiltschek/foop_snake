#! /usr/bin/ruby -w

require 'sdl'
require 'logger'

require "#{File.dirname(__FILE__)}/../common/Snake"

class Client

	def initialize
		@w = 640
		@h = 480

		SDL.init SDL::INIT_VIDEO
		
		@screen	 = SDL::set_video_mode @w, @h, 24, SDL::SWSURFACE
		@BGCOLOR = @screen.format.mapRGB 0, 0, 0

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
		@screen.fill_rect 0, 0, 640, 480, @BGCOLOR

		snakes.each do |snake|
			snake.get_tail.each do |t|
				@screen.fill_rect t.get_x*8 % @w, t.get_y*8 % @h, 8, 8,t.get_color
			end
		end

		@screen.flip	
	end

	def run
		snakes = Array.new

		player = Snake.new(8, 8, 123456, "Clyde")
		snakes.push(player)
		
		# just for fun
		snakes.push(Snake.new(40, 40, 98765, "Pinky"))
		snakes.push(Snake.new(15, 15, 8000000, "Blinky"))
		snakes.push(Snake.new(60, 15, 4324324, "Inky"))
	
		@running = true
		
		t = Time.now

		# main loop
		while @running
			d = (Time.now - t) * 1000 

			# this should be sent to the server
			direction = handle_input
			if direction != nil then
				dir = direction
			end

			# tick
			if (d > 100) then
				t = Time.now
				@log.info "tick"

				# receive game-related stuff from server TODO
				# send directions to server TODO

				# this should go on the server side
				snakes.each do |snake|

					if snake == player then

						# growth and stuff
						snake.update(d, dir)

						# movement
						snake.move(dir, snakes)

					else
						# funstuff again, just for having something to watch
						case rand(4)

							when 0
								rdir = :up

							when 1
								rdir = :right

							when 2
								rdir = :left

							when 3
								rdir = :down

						end

						snake.update(d, rdir)
						snake.move(rdir, snakes)
					end
				end
			end
			
			draw(snakes)
		end
	end
end

c = Client.new
c.run
