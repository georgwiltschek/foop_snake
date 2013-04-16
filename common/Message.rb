require 'json'
require "./common/Snake"

class Message

	attr_accessor :type, :msg

	def initialize type, msg
		@type = type
		@msg = msg  

		puts "d #{msg.size} #{msg[0].class}"
puts"2222"
	end

	def self.json_create(o)
		new(*o['data'])
	end

	def to_json(*a)
		{
			'json_class' => self.class.name, 
			'data' => [@type, @msg]
		 }.to_json(*a)
	end

end