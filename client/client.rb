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

class Client
  # constructor
  def initialize(ip, port)

    @running    = false
    @log        = Logger.new(STDOUT)
    @serverip   = Settings.host
    @serverport = Settings.port

    @renderer = Renderer.new
  end

  def handle_input
    event = SDL::Event2.poll

    case event
      # quit
      when SDL::Event2::Quit
        @running = false
        return

      # other keys
      when SDL::Event2::KeyDown
        case event.sym
          # quit via escape
          when SDL::Key::ESCAPE
            @running = false
            return

          # directions
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

  def connect_to_server
    @socket = TCPSocket.open(@serverip, @serverport)
  end
  
  # send the direction to the server
  def send_direction(direction)
    package = {"direction"  => direction}
    @log.info jsonPackage = JSON.dump(package)
    
    @socket.puts(jsonPackage)
  end
  
  # gets game state from server
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
    changed  = false
    @snakes  = Array.new
    @running = true
    lastdir  = nil

    die "can't connect to server" unless connect_to_server

    t = Time.now

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