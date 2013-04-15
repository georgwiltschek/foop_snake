require 'json'

class Message

	attr_accessor :type, :msg

	def initialize type, msg
		@type = type
		@msg = msg   
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