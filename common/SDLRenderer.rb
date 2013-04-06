require "./common/Settings"

# Simple SDL based, double buffered renderer
class Renderer
  def initialize
    @scale  = Settings.scale
    @w      = Settings.w
    @h      = Settings.h
    @colors = Settings.colors
    
    # SDL init
    SDL.init SDL::INIT_VIDEO
    @screen  = SDL::set_video_mode @w * @scale, @h * @scale, 24, SDL::SWSURFACE
    @BGCOLOR = 0x000000 # black
  end
  
  # draw everything
  def draw snakes
    # background
    @screen.fill_rect 0, 0, @w * @scale, @h * @scale, @BGCOLOR

    # draw the snakes
    snakes.each do |snake|
      first = true
      snake.get_tail.each do |t|
        if first then # heads should be different than tails
          @screen.fill_rect t.x * @scale, t.y * @scale, @scale - 1, @scale - 1, @colors[t.color.to_sym][:c]
          first = false
        else
          draw_rect t.x * @scale, t.y * @scale, @scale - 1, @scale - 1, @colors[t.color.to_sym][:c]
        end
      end
    end

    # draw the rules
    i = 0
    (@colors.sort_by {|k, v| v[:i]}).each do | color |
      draw_rect i * @scale, 0 * @scale, @scale, @scale, @colors[color[0].to_sym][:c]
      i += 1.5
    end

    @screen.flip    
  end
  
  # somehow this SDL function got lost somewhere between ruby 1.8.* and 1.9.*...
  def draw_rect x, y, w, h, c
    @screen.fill_rect x, y, w, h, c
    @screen.fill_rect x + 1, y + 1, w - 2, h - 2, 0x000000
  end
end