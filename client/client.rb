#! /usr/bin/ruby -w

require 'rubygems'
require 'sdl'
require 'logger'
require 'json'
require 'socket'

require "./common/Snake"
require "./common/Settings"
require "./common/Message"

if (ARGV.include? "-opengl") then
  require "./client/opengl/OpenGLRenderer"
else
  require "./client/sdl/SDLRenderer"
end

# TODO show score
# TODO know which snake belongs to the client (and highlight it in the renderer somehow)
# TODO show death and other messages
# TODO messaque queue or something for comm

class Client
  # constructor
  def initialize(ip, port)

    @running    = false
    @log        = Logger.new(STDOUT)
    @serverip   = Settings.host
    @serverport = Settings.port
    @renderer   = Renderer.new
  end

  # handle keyboard and other events
  def handle_input
    case event = SDL::Event2.poll
      when SDL::Event2::Quit    then @running = false
      when SDL::Event2::KeyDown
        case event.sym
          when SDL::Key::ESCAPE then @running = false
          when SDL::Key::LEFT   then direction = :left
          when SDL::Key::RIGHT  then direction = :right
          when SDL::Key::UP     then direction = :up
          when SDL::Key::DOWN   then direction = :down        
        end

        @log.info "Key Event: #{event.sym} #{direction}"
        return direction
    end
  end

  # open a connection to the server
  def connect_to_server
    @socket = TCPSocket.open(@serverip, @serverport)
  end
  
  # send the direction to the server
  def send_direction(direction)    
    msg = Message.new("update_direction", direction)
    puts JSON.dump(msg)
    @socket.puts(JSON.dump(msg))


  end
  
  # gets game state update from server
  def get_update
    line = @socket.gets.chop

    die "connection lost" if !line

    update = JSON.parse(line, :create_additions => true)

    case update.type.to_sym
      when :update_snakes
        update.msg = JSON.parse(update.msg, :create_additions => true)
        update_snakes update.msg
      when :update_colors      
        @renderer.update_colors update.msg
      when :identity
    puts line
        #TODO it's me! do something!
    end
  end

  # update each snake
  def update_snakes update
    # on client start, create all the local snakes from the first update
    if @snakes.size == 0 then
      update.each do |snake|
        s = Snake.new(0, 0, 0x000000, snake["name"], nil, 0, 0)
        @snakes.push(s)
      end
    end

    update.each do |snake|
      @snakes.select { |s| snake["name"] == s.get_name}.map { |ss| ss.update_tail snake["tail"]}
    end
  end

  def run
    @snakes  = Array.new
    @running = true
    changed  = false
    lastdir  = nil
    t        = Time.now

    die "can't connect to server" unless connect_to_server

    # main game loop
    while @running
      d = (Time.now - t) * 1000 # elapsed time since last tick

      # get direction changes from input handler
      direction = handle_input
      if direction != nil then
        changed = lastdir != direction
        lastdir = dir = direction
      end

      # tick
      if (d > 10) then
        t = Time.now

        # send direction if changed
        if changed
          send_direction(dir)
          changed = false
        end

        # get updated gamestate from server
        get_update
      end

      @renderer.draw(@snakes)
    end
  end
end

# create and run new client
c = Client.new(Settings.host, Settings.port)
c.run