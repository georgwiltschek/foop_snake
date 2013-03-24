
class ClientProxy
  attr_accessor :client :lastInput
  
  def turn
    
    if @client then
      line = @client.gets
      puts line
    end
    
    
    
  end
  
end