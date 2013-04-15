require 'json'

class Message

	attr_accessor :type, :msg

	def initialize(type, msg)
		@type = type
		@msg = msg   
	end

	def to_json(*a)
	{
		'json_class'   => self.class.name,
		'type'		   => @type,
		'data'         => @msg
	}.to_json(*a)
	end

    def self.from_json string
        data = JSON.load string
        self.new data['type'], JSON.parse(data['data'], :create_additions => true)
    end


end