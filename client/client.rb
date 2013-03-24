#! /usr/bin/ruby -w

require 'sdl'
require 'logger'
require 'rubygems'
require 'json'

require "#{File.dirname(__FILE__)}/../common/Snake"

class Client

	def initialize
		@scale = 8
		@w = 640 / 8
		@h = 480 / 8

		SDL.init SDL::INIT_VIDEO
		
		@screen	 = SDL::set_video_mode @w * @scale, @h * @scale, 24, SDL::SWSURFACE
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

	def run
		snakes = Array.new

		mode = :snake # or :tron :-)

		player = Snake.new(8, 8, 123456, "Clyde", mode, @w, @h)
		snakes.push(player)
		
		# just for fun and testing
		snakes.push(Snake.new(40, 40, 98765,   "Pinky",  mode, @w, @h))
		snakes.push(Snake.new(15, 15, 8000000, "Blinky", mode, @w, @h))
		snakes.push(Snake.new(60, 15, 4324324, "Inky",   mode, @w, @h))
	
		@running = true	
		t = Time.now
		# main loop
		while @running
			d = (Time.now - t) * 1000 # elapsed time since last tick

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

				# this should go on the server side TODO
				snakes.each do |snake|

					if snake == player then

            snake.update_tail(player.get_tail.to_json)

						# growth and stuff
						snake.update(d, dir)

						# movement
						snake.move(dir, snakes)
            
            # p player.get_tail.first

            # if player.get_tail.first == JSON.parse(JSON.dump(player.get_tail.first)) then
#               puts "YES"
#             end

					else
						# "AI" snakes
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

# create and run new client
c = Client.new
c.run