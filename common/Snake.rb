class Snake

	# Constructor
	def initialize x, y, color
		@log = Logger.new(STDOUT)
		@pos_x = x
		@pos_y = y
		@color = color
		@tail = Array.new			# the whole snake
		@tail.push(self)
		@grow = 9 					# initial growth
	end

	# move and detect collisions
	def move direction, snakes

		# no straight backwards
		if opposite(@lastdirection) == direction then
			direction = @lastdirection
		end

		@lastdirection = direction
		next_x = @pos_x
		next_y = @pos_y

		# calculate next position
		case direction
			when :right
				next_x = @pos_x + 1

			when :left
				next_x = @pos_x - 1

			when :down
				next_y = @pos_y + 1

			when :up
				next_y = @pos_y - 1
		end

		# collision detection
		snakes.each do |snake|

			snake.get_tail.each do |segment|
				if next_x == segment.get_x &&
				   next_y == segment.get_y &&
				   snake.get_tail.index(segment) != 0 # head collision TODO
				then

	   				if snake == self
	   					# collision with self, do nothing
						@log.info 'collision with self detected'
					else
						# collision with other snake, eat & grow
						@log.info 'collision detected'
						@grow = snake.remove_from_segment(segment)
					end

					# one collision is enough, return
					return

				end
			end
		end

		# last segment set to position of first
		@tail.last.set_y(@tail.first.get_y)
		@tail.last.set_x(@tail.first.get_x)
		
		# insert last segment as second segment
		if @tail.length > 1 then
			last = @tail.pop
			@tail.insert(1, last)
		end

		@tail.first.set_x(next_x)
		@tail.first.set_y(next_y)
	end

	# remove all segments starting with segment, return numer of 
	# removed segments
	def remove_from_segment segment
		total = @tail.length
		@tail.slice!(@tail.index(segment), @tail.length)
		return total - @tail.length
	end

	# update snake (i.e. stuff, that's not really movement, but also important.
	# at the moment it does growth only)
	def update delta, direction
		# let the snake grow for a while

		if @tail.length == 0 then
			#die
			return
		end

		if @grow > 0 then

			case direction

				when :right
					t = Snake.new(@tail.last.get_x - 1, @tail.last.get_y, @tail.last.get_color)

				when :left
					t = Snake.new(@tail.last.get_x + 1, @tail.last.get_y, @tail.last.get_color)

				when :up
					t = Snake.new(@tail.last.get_x, @tail.last.get_y + 1, @tail.last.get_color)

				when :down
					t = Snake.new(@tail.last.get_x, @tail.last.get_y - 1, @tail.last.get_color)

			end

			if t != nil then
				@tail.push(t)
				@grow = @grow - 1
			end
		end
	end

	# get the opposite direction of d
	def opposite d
		case d

			when :left
				return :right

			when :right
				return :left

			when :up
				return :down

			when :down
				return :up

		end

		return nil
	end

	####################################################
	##
	## Getter/Setter
	##
	####################################################

	def get_tail
		return @tail
	end

	def get_x
		return @pos_x
	end

	def get_y
		return @pos_y
	end
	
	def set_x x
		@pos_x = x
	end

	def set_y y
		@pos_y = y
	end

	def get_color
		return @color
	end

	def set_color c
		@color = c
	end

end
