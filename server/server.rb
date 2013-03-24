require "../common/Config"
require 'socket'
require "client-proxy"

class Server
  
  class Slot
    :attr client
    :attr snake
  end
  
  def initialize
    snakes = Array.new
    #@lastInput = Array.new
    @slots = Array.new
    
		snakes.push(Snake.new(8, 8, 123456, "Clyde", mode, @w, @h))  
		snakes.push(Snake.new(40, 40, 98765,   "Pinky",  mode, @w, @h))
		snakes.push(Snake.new(15, 15, 8000000, "Blinky", mode, @w, @h))
		snakes.push(Snake.new(60, 15, 4324324, "Inky",   mode, @w, @h))
    
    snakes.each do |snake|
      @slots.push mew Slot(new ClientProxy, snake)
    end
    
    @running = true
    
  end
  
  
  def run
    
    
    @server = TCPServer.open(Config.new.port)
    Thread.start { listen_for_clients }
    
    while @running
			d = (Time.now - t) * 1000 # elapsed time since last tick

			# tick
			if (d > 100) then
				t = Time.now
				@log.info "tick"
        
        snakes = @slots.map {|s| s.snake}
        
        @slots.each do |slot|
          direction = slot.client.get_last_input
          
          # growth and stuff
          slot.snake.update(d,direction)
          
          # movement
          slot.snake.move(direction, snakes)
          
          slot.client.update(snakes)
          
        end
        
      end
    
    end
    
  end
  
  def listen_for_clients
    while @running
      client = @server.accept
      slot = get_slot(client)
      Thread.start(slot) do |slot|
        slot.listen_for_input
    end
  end
  
  def get_slot(client)
    for i in 0..@slots.size
      if @slots[i].isBot then
        @slots[i].isBot = false
        @solts[i].client = client
        return @slots[i]
      end
    end
  end
  
end