require 'sdl'
require 'opengl'
require 'gl'
require 'mathn'
require "./common/Shader"
require "./common/Settings"
require 'rubygems'
require 'md2'
include Gl, Glu, Glut

LIGHT_POS = [100.0, 0.0, 100.0, 1.0]


class MD2Viewer
  def initialize
    @scale  = Settings.scale
    @w      = Settings.w
    @h      = Settings.h
    @width = @w * @scale
    @height = @h * @scale
    @colors = Settings.colors
    @log    = Logger.new(STDOUT)
    @doBloom = true
    @doBlur  = true
    @doTunnelblick  = true

    @mousePosition = [0,0]

    SDL.init(SDL::INIT_VIDEO)
    SDL.setGLAttr(SDL::GL_DOUBLEBUFFER,1)
    SDL.setVideoMode(@w * @scale, @h * @scale,32,SDL::OPENGL | SDL::GL_DOUBLEBUFFER | SDL::HWSURFACE)
    # glViewport(-@w * @scale/2, -@h * @scale/2,@w * @scale/2, @h * @scale/2)
    
    
    GL.Enable(GL::DEPTH_TEST)
    GL.Enable(GL::CULL_FACE)
    GL.Enable(GL::LIGHTING)
    GL.Lightfv(GL::LIGHT0, GL::POSITION, LIGHT_POS)
    GL.Enable(GL::LIGHT0)
    GL.ShadeModel(GL::SMOOTH)
    GL.Enable(GL::NORMALIZE)
    
  end
  
  def run
    md2 = MD2.new("./common/hobgoblin.md2")
    
    frameNr = 0
    while true
      frame = md2.frames[frameNr]
      frameNr = frameNr + 1
      
      glMatrixMode(GL_PROJECTION);
      glLoadIdentity();
      glOrtho(0, @w * @scale, @h * @scale, 0, 1000.0, -1000.0);
      glMatrixMode(GL_MODELVIEW);
      glLoadIdentity()
      GL.LoadIdentity()
    
      GL.Clear(GL::COLOR_BUFFER_BIT | GL::DEPTH_BUFFER_BIT)
      glPushMatrix
      glTranslate 300,300,0
      md2.gl_commands.each do |command|
        case command.type
          when :triangle_strip then glBegin(GL_TRIANGLE_STRIP)
          when :triangle_fan   then glBegin(GL_TRIANGLE_FAN)
        end

        command.segments.each do |segment|
          index = segment.vertex_index

          glTexCoord2f(segment.texture_s, segment.texture_t)
          # glNormal3f(frame.normals[index].x, frame.normals[index].y, frame.normals[index].z)
          glVertex3f(frame.vertices[index].x, frame.vertices[index].y, frame.vertices[index].z)
        end

        glEnd
      end
      glPopMatrix
      SDL.GL_swap_buffers 
      
    end
  end
  
end

viewer = MD2Viewer.new
viewer.run