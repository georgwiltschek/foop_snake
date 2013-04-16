require 'logger'
require "./common/Message"

class ClientProxy
  attr_accessor :client, :lastInput, :isBot
  
  def initialize
    @isBot = true
    @log = Logger.new(STDOUT)
  end
  
  def listen_for_input
    @log.info "start listening"
    while true
      line = @client.gets.chop
      break if !line
      
      json = JSON.parse(line)

      if json["direction"] then
        @lastInput = json["direction"].to_sym
      end
      
    end
  end
  
  # TODO here would be a good place for some magic :)
  def get_last_input
    if !@client then
      case rand(4)
        when 0
            @lastInput = :up
        when 1
            @lastInput = :right
        when 2
            @lastInput = :left
        when 3
            @lastInput = :down
      end
    end

    return @lastInput
  end

  def update update
    case update.type.to_sym
      when :update_snakes
        snakes = update.msg       
        if @client
          begin
            stonedSnakes = snakes.map { |s| {"name" => s.get_name, "tail" => s.get_tail.to_json} }
            stoneColdKilledSnakes = JSON.dump(stonedSnakes)
            msg = Message.new("update_snakes", stoneColdKilledSnakes)
            @client.puts(JSON.dump(msg))
          rescue Exception => myException
            @log.info "Exception rescued: #{myException}"
            @client = nil
            @isBot = true
          end   
        end
      when :update_colors
        if @client
          @client.puts(JSON.dump(update))
        end
      when :identity

        # so far so goos
        puts JSON.dump(update)
        puts update.type
        puts update.msg

        # but this fails
#         @client.puts(JSON.dump(Message.new("identity", hash)))
      end
  end
end