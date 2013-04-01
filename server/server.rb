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
      return snake.name
    end
      
  end
  
  def initialize
    snakes = Array.new
    #@lastInput = Array.new
    @slots = Array.new
		@log = Logger.new(STDOUT)
		@w = 640 / 8
		@h = 480 / 8
    mode = :snake # or :tron
    
		snakes.push(Snake.new(8, 8, 123456, "Clyde", mode, @w, @h))  
		snakes.push(Snake.new(40, 40, 98765,   "Pinky",  mode, @w, @h))
		snakes.push(Snake.new(15, 15, 8000000, "Blinky", mode, @w, @h))
		snakes.push(Snake.new(60, 15, 4324324, "Inky",   mode, @w, @h))
    
    snakes.each do |snake|
      @slots.push Slot.new(ClientProxy.new, snake)
    end
    
    @running = true
    
  end
  
  
  def run
    
    
    @server = TCPServer.open(9876)
    Thread.start { listen_for_clients }
    
		t = Time.now
    while @running
			d = (Time.now - t) * 1000 # elapsed time since last tick

			# tick
			if (d > 100) then
				t = Time.now
        # @log.info "tick"
        
        snakes = @slots.map {|s| s.snake}
      
        @slots.each do |slot|
          slot.direction = slot.client.get_last_input          # 
        end

        # growth and stuff
        @slots.each do |slot|          
          slot.snake.update(d , slot.direction)
        end
          
        @slots.each do |slot|
          # movement
          if !slot.snake.isDead
            slot.snake.move(slot.direction, snakes)
          end
        end

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

server = Server.new
server.run
