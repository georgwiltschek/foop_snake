require "./common/Settings"

class Snake
	attr_accessor :isDead, :score, :pos_x, :pos_y, :name

	class Tail
		attr_accessor :x, :y, :color, :snake, :isDead

		# Tail Constructor
		def initialize (x, y, color, snake)
			@x = x
			@y = y
			@color = color
			@snake = snake
		end

		def self.json_create(o)
			new(*o['data'])
#			new(o['data']['x'],o['data']['y'],o['data']['color'],nil)
		end

		def to_json(*a)
		{
			'json_class' => self.class.name, 
			'data' => [@x, @y, @color, nil]
		}.to_json(*a)
		end


		# def to_json(*a)
		# 	{
		# 		'json_class'   => self.class.name,
		# 		'data'         => {"x" => @x , "y" => @y, "color" => @color},
		# 	}.to_json(*a)
		# end

		# def self.json_create(o)
		# 	new(o['data']['x'],o['data']['y'],o['data']['color'],nil)
		# endnil
	end

	# Snake Constructor
	def initialize x, y, color, name, mode, w, h
		@log    = Logger.new(STDOUT)
		@tail   = Array.new # the whole snake, despite the name :)
		@mode   = mode
		@pos_x  = x
		@pos_y  = y
		@color  = color
		@name   = name
	    @scale  = Settings.scale
    	@w      = Settings.w
    	@h      = Settings.h
      	@isDead = false
      	@score  = 0

		@colors = Settings.colors

		# initial growth
		if mode == :snake then
			@grow = 9
		else
			@grow = 0
		end

		# add self as first segment of the snake
		@tail.push(Tail.new(@pos_x,@pos_y,@color,self))
	end
	
	def update_tail(jsonTail)
		@tail.clear
		newTail = JSON.parse(jsonTail, :create_additions => true)
		
		newTail.each do |o|
			@tail.push(Tail.new(o.x, o.y, o.color, self))
		end
	end

	# move and detect collisions
	def move direction, snakes
    return if @mode != :snake
    
		# no straight backwards
		if opposite(@lastdirection) == direction then
			direction = @lastdirection
		end

		@lastdirection = direction
		next_x = @tail.first.x
		next_y = @tail.first.y

		# calculate next position
		case direction
			when :right
				next_x = next_x + 1
			when :left
				next_x = next_x - 1
			when :down
				next_y = next_y + 1
			when :up
				next_y = next_y - 1
		end

		# collision detection
		snakes.each do |snake|
    
			snake.get_tail.each do |segment|
				if next_x == segment.x && next_y == segment.y && snake.get_tail.index(segment) != 0 then

					# snake chops of another snakes tail
					if snake == self
						# collision with self, do nothing
						
					else
						# collision with other snake, eat & grow
						# @log.info "#{self.get_name}: collision with #{segment.snake.get_name} detected"
						@grow = @grow + snake.remove_from_segment(segment)
					end

					# one collision is enough, return
					return

				elsif next_x == segment.x && next_y == segment.y && snake.get_tail.index(segment) == 0 then

					# head collisions
					if @colors[snake.get_color.to_sym][:i] < @colors[self.get_color.to_sym][:i]
						# checking snake eats checked snake
						# @log.info "#{self.get_name}: Omnomnomnom";
						@grow = @grow + snake.remove_from_segment(snake.get_tail.first)
					end

				end
			end
		end

		# in tron mode, always grow 1
		if @mode == :tron then @grow = 1 end

		# last segment set to position of first
		@tail.last.y = (@tail.first.y % @h)
		@tail.last.x = (@tail.first.x % @w)
		
		# insert last segment as second segment
		if @tail.length > 1 then
			last = @tail.pop
			@tail.insert(1, last)
		end

		@tail.first.x = (next_x % @w)
		@tail.first.y = (next_y % @h)
	end

	# remove all segments starting with segment, return numer of 
	# removed segments
	def remove_from_segment segment
		if @mode == :tron then return 0 end

		total = @tail.length
		@tail.slice!(@tail.index(segment), @tail.length)

		if @tail.length <= 0 
			@isDead = true
		end
		
		return total - @tail.length
	end

  def resurrect
    @isDead = false
		@tail.push(Tail.new(rand(@w),rand(@h),@color,self))
  end

	def update_colors colors
		@colors = colors
	end

	# update snake (i.e. stuff, that's not really movement, but also important.
	# at the moment it does growth only)
	def update delta, direction
		if @tail.length == 0 then
			#die
			@isDead = true;
			return
		end

		if @grow > 0 then
			case direction
				when :right
					t = Tail.new(@tail.last.x - 1, @tail.last.y, @tail.last.color,self)
				when :left
					t = Tail.new(@tail.last.x + 1, @tail.last.y, @tail.last.color,self)
				when :up
					t = Tail.new(@tail.last.x, @tail.last.y + 1, @tail.last.color,self)
				when :down
					t = Tail.new(@tail.last.x, @tail.last.y - 1, @tail.last.color,self)
			end

			if t != nil then
				@tail.push(t)
				@grow = @grow - 1
				@score = @score + 1
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

	def get_color
		return @color
	end

	def get_name
		return @name
	end

	def set_color c
		@color = c
	end
end
