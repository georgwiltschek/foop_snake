class Snake
	def initialize x, y, color
		@pos_x = x
		@pos_y = y
		@color = color
		@tail = Array.new
		@tail.push(self)
	end

	def opposite(d)
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

	def move direction
		if opposite(@lastdirection) == direction then
			direction = @lastdirection
		end

		@lastdirection = direction

		# last segment set to position of first
		@tail.last.set_y(@tail.first.get_y)
		@tail.last.set_x(@tail.first.get_x)
		
		# insert last segment as second segment
		if @tail.length > 1 then
			last = @tail.pop
			@tail.insert(1, last)
		end

		# move first segment
		case direction
			when :right
				@tail.first.set_x(@pos_x = @pos_x + 1)
			when :left
				@tail.first.set_x(@pos_x = @pos_x - 1)
			when :down
				@tail.first.set_y(@pos_y = @pos_y + 1)
			when :up
				@tail.first.set_y(@pos_y = @pos_y - 1)
		end
	end

	def update delta, direction
		# let the snake grow for a while
		if @tail.length < 20 then
			case direction
				when :right
					t = Snake.new(@tail.last.get_x - 1, @tail.last.get_y, @tail.last.get_color)

				when :left
					t = Snake.new(@tail.last.get_x + 1, @tail.last.get_y, @tail.last.get_color)

				when :up
					t = Snake.new(@tail.last.get_x,     @tail.last.get_y + 1, @tail.last.get_color)

				when :down
					t= Snake.new(@tail.last.get_x, @tail.last.get_y - 1, @tail.last.get_color)
			end

			if t != nil then
				@tail.push(t)
			end
		end
	end

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
end
