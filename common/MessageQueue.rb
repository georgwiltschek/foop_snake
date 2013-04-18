require 'socket'
require 'logger'

require "./common/Message"

class MessageQueue

	attr_accessor :receiver

	def initialize receiver
		@messages = Array.new
		@receiver = receiver
		@log      = Logger.new(STDOUT)
		@lock     = false

	end

	def add_message msg
		@messages.push(msg)
	end

	def send_messages
		if @messages.size == 0 then 
			@log.info("queue empty")
			return 
		end

		sent = Array.new
		@messages.each do | msg |
			@receiver.puts(msg)
			sent.push(msg)
		end

		@log.info("sent #{sent.size} messages")

		# clean up
		sent.each do | msg |
			@messages.delete(msg)
		end
	end

end