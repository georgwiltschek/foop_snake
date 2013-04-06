module Settings
  extend self

  attr_reader :host, :port, :colors, :w, :h, :scale

  @host   = "localhost"
  @port   = 9876

  @scale  = 8
  @w      = 640 / @scale
  @h      = 480 / @scale

  @colors = {
    :red     => {:c => 0xAD3333, :i => 0},
    :green   => {:c => 0x5CE65C, :i => 1},
    :yellow  => {:c => 0xFFF666, :i => 2},
    :blue    => {:c => 0x3366FF, :i => 3},
    :purple  => {:c => 0xFF70B8, :i => 4},
    :orange  => {:c => 0xFFC266, :i => 5},
    :white   => {:c => 0xFFFFFF, :i => 6},
    :grey    => {:c => 0x888888, :i => 7},
    :magenta => {:c => 0xca1f7b, :i => 8}
  }
end