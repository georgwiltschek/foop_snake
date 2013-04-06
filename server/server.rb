require "rubygems"
require "json"
require "logger"
require 'socket'
require "./server/client-proxy"
require "./common/Snake"
require "./common/Settings"

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

    @scale      = Settings.scale
    @w          = Settings.w
    @h          = Settings.h

    @log = Logger.new(STDOUT)

    @colors = Settings.colors

    # generate snakes
    # TODO get all these from cmdline and/or config
    names      = ["Clyde", "Pinky", "Inky", "Blinky"]
    mode       = :snake # or :tron

    (1..num_snakes).each do |n|
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
    @server = TCPServer.open(Settings.port)
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
          snakes.each do | snake |
            @log.info "#{snake.get_name} score: #{snake.score}"
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
        @log.info "new client connected"
        slot = get_slot(client)
        @log.info "client got slot " #+ @slots[i]
        slot.client.listen_for_input
      end
    end
  end
  
  def get_slot(client)
    @slots.each do |slot|
      @log.info "."
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
