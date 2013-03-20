#! /usr/bin/ruby -w

require 'sdl'
require 'logger'
require "#{File.dirname(__FILE__)}/../common/Snake"

class Client

	def initialize
		SDL.init SDL::INIT_VIDEO
		@w = 640
		@h = 480
		@screen = SDL::set_video_mode @w, @h, 24, SDL::SWSURFACE
		x = y = 0

		@BGCOLOR   = @screen.format.mapRGB 0, 0, 0

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
				end

			@log.info("Key Event: #{event.sym} #{direction}")
			return direction
		end
	end

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

		snake = Snake.new(8,8,123456)
		snakes.push(snake)
		
		# just for fun
		snake2 = Snake.new(40,40,98765)
		snakes.push(snake2)
	
		@running = true
		
		t = Time.now

		# main loop
		while @running
			d = (Time.now - t) * 1000
			direction = handle_input
			if direction != nil then
				dir = direction
			end

			if (d > 100) then
				t = Time.now
				@log.info("tick")
				snakes.each do |snake|
					# growth and stuff
					snake.update(d, dir)
					# movement
					snake.move(dir)
				end
			end
			
			draw(snakes)
		end
	end
end

c = Client.new
c.run
