
class Config
  attr_accessor :ip, :port
  
  def initialize
    @ip = "localhost"
    @port = 9876
  end
end