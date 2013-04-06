class Renderer
  
  def initialize
    @scale      = 8
    @w          = 640 / @scale
    @h          = 480 / @scale
    
    # TODO dupe. put into config or somewhere else
    @colors = {
      :red    => {:c => 0xAD3333, :i => 0},
      :green  => {:c => 0x5CE65C, :i => 1},
      :yellow => {:c => 0xFFF666, :i => 2},
      :blue   => {:c => 0x3366FF, :i => 3},
      :purple => {:c => 0xFF70B8, :i => 4},
      :orange => {:c => 0xFFC266, :i => 5},
      :white  => {:c => 0xFFFFFF, :i => 6}
    }
    
    # SDL init
    SDL.init SDL::INIT_VIDEO
    @screen  = SDL::set_video_mode @w * @scale, @h * @scale, 24, SDL::SWSURFACE
    @BGCOLOR = @screen.format.mapRGB 0, 0, 0 # black background
  end
  
  # draws all the snakes
  def draw snakes
    @screen.fill_rect 0, 0, @w * @scale, @h * @scale, @BGCOLOR
    snakes.each do |snake|
      first = true
      snake.get_tail.each do |t|
        if first then
          @screen.fill_rect t.x * @scale, t.y * @scale, @scale - 1, @scale - 1, @colors[t.color.to_sym][:c]
          first = false
        else
          draw_rect t.x * @scale, t.y * @scale, @scale - 1, @scale - 1, @colors[t.color.to_sym][:c]
        end
      end
    end

    # draw rules
    i = 0
    (@colors.sort_by {|k, v| v[:i]}).each do | color |
      draw_rect i * @scale, 0 * @scale, 8, 8, @colors[color[0].to_sym][:c]
      i += 1.5
    end

    @screen.flip    
  end
  
  def draw_rect x, y, w, h, c
    @screen.fill_rect x,y,w,h,c
    @screen.fill_rect x+1,y+1,w-2,h-2,0x000000
  end
  
end
