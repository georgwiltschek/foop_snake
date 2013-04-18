require 'logger'
require "./common/Message"
require "./common/MessageQueue"

class ClientProxy
  attr_accessor :client, :lastInput, :isBot
  
  def initialize
    @isBot = true # always start as bot
    @log   = Logger.new(STDOUT)
    @mq    = MessageQueue.new(self)
  end

  def set_client client
    @mq.receiver = @client = client
  end

  # listen for messages of the associated client  
  def listen_for_input
    @log.info "start listening"
    while true
      line = @client.gets.chop
      break if !line

      msg = JSON.parse(line, :create_additions => true)

      case msg.type.to_sym
        when :update_direction
          @lastInput = msg.msg.to_sym
        when :request_update
          @mq.send_messages
      end
    end
  end
  
  # FIXME here would be a good place for some magic :)
  def get_last_input
    if !@client then
      case rand(4)
        when 0 then @lastInput = :up
        when 1 then @lastInput = :right
        when 2 then @lastInput = :left
        when 3 then @lastInput = :down
      end
    end

    return @lastInput
  end

  # gets update from server, relays it to real clients if any
  def update update
    return unless @client

    case update.type.to_sym
      when :update_snakes
        snakes = update.msg       
        begin
          stonedSnakes = snakes.map { |s| {"name" => s.get_name, "tail" => s.get_tail.to_json} }
          stoneColdKilledSnakes = JSON.dump(stonedSnakes)
          msg = Message.new("update_snakes", stoneColdKilledSnakes)
          @mq.add_message(JSON.dump(msg))
          # @client.puts(JSON.dump(msg))
        rescue Exception => myException
          @log.info "Exception rescued: #{myException}"
          @client = nil
          @isBot = true
        end   
      when :update_colors
        @mq.add_message(JSON.dump(update))
      when :identity
        @mq.add_message(JSON.dump(update))
      end
  end
end