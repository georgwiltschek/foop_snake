require "rubygems"
require "json"
require "logger"
require 'socket'
require "#{File.dirname(__FILE__)}/client-proxy"
require "#{File.dirname(__FILE__)}/../common/Snake"

class Server
  
  class Slot
    attr_accessor :client, :snake, :direction
    
    def initialize client, snake
      @client = client
      @snake = snake
    end
    
    def to_s
      return @snake.name
    end

  end
  
  def initialize num_snakes
    snakes = Array.new
    #@lastInput = Array.new
    @slots = Array.new
		@w = 640 / 8
		@h = 480 / 8
    @log = Logger.new(STDOUT)

    # TODO put into config
    # TODO actually, start using config first
    @colors = {
      :red    => {:c => 0xAD3333, :i => 0},
      :green  => {:c => 0x5CE65C, :i => 1},
      :yellow => {:c => 0xFFF666, :i => 2},
      :blue   => {:c => 0x3366FF, :i => 3},
      :purple => {:c => 0xFF70B8, :i => 4},
      :orange => {:c => 0xFFC266, :i => 5},
      :white  => {:c => 0xFFFFFF, :i => 6}
    }

    # generate snakes
    # TODO get all these from cmdline and/or config
    names      = ["Clyde", "Pinky", "Inky", "Blinky"]
    mode       = :snake # or :tron

    (0..num_snakes).each do |n|
      name = "#{names[n % names.size]}#{n}"
      x    = rand(@w)
      y    = rand(@h)
      mode = :snake
      c    = @colors.keys[rand(@colors.keys.length)]
  
      s = Snake.new(x, y, c,  name,  mode, @w, @h)
      @slots.push Slot.new(ClientProxy.new, s)
      snakes.push(s)
    end

    @running = true
  end
  
  # main server loop
  def run
    @server = TCPServer.open(9876)
    Thread.start { listen_for_clients }

    dc = 0    
		t = Time.now
    while @running
			d = (Time.now - t) * 1000 # elapsed time since last tick

			# tick
			if (d > 100) then
				t      = Time.now
        colors = nil
        dc    += 1

        snakes = @slots.map {|s| s.snake}
      
        @slots.each do |slot|
          slot.direction = slot.client.get_last_input
        end

        # rules change
        if (dc > 100) then
          dc = 0
          @colors.each do | color |
            @colors[color[0].to_sym][:i] = rand(@colors.size * 50)
          end
          colors = @colors
          @log.info "rules change #{@colors.inspect}"
          snakes.each do |snake|
            @log.info "#{snake.to_s} score: #{snake.score}"
          end
        end

        # growth and stuff
        @slots.each do |slot|          
          slot.snake.update(d , slot.direction)
          if colors != nil then
            slot.snake.update_colors colors
          end
        end
          
        # movement
        @slots.each do |slot|
          if !slot.snake.isDead
            slot.snake.move(slot.direction, snakes)
          end
        end

        # updates to clients
        @slots.each do |slot|
          slot.client.update(snakes)
        end
        
      end
    
    end
    
  end
  
  def listen_for_clients
    while @running
      client = @server.accept
      Thread.start(client) do |client|
        # slot.listen_for_input
        puts "new client connected"
        slot = get_slot(client)
        puts "client got slot " #+ @slots[i]
        slot.client.listen_for_input
      end
    end
  end
  
  def get_slot(client)
    @slots.each do |slot|
      puts "."
      if slot.client.isBot == true then
        slot.client.isBot = false
        slot.client.client = client
        return slot
      end
    end
  end
end

# run server
num_snakes = 4
@log = Logger.new(STDOUT)

if ARGV[0] != nil && ARGV[0].to_i > 0 then
  num_snakes = ARGV[0]
end

@log.info "Starting server with #{num_snakes} snakes..."
server = Server.new(num_snakes.to_i)
server.run
