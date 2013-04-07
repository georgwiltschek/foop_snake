class Shader
  
  @shaderProgram = nil
  
  def initialize shader_base_file_name
    # Create GLSL program and shader objects
    glsl_program = GL.CreateProgram()
    glsl_vertex_shader = GL.CreateShader(GL_VERTEX_SHADER)
    glsl_fragment_shader = GL.CreateShader(GL_FRAGMENT_SHADER)

    # Load shader source into the shaders
    
    vshPath = "./common/#{shader_base_file_name}.vsh"

    if File.exists?(vshPath) then 
      GL.ShaderSource(glsl_vertex_shader,File.read(vshPath))
    else
      GL.ShaderSource(glsl_vertex_shader,"attribute vec4 pos; void main() { gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex; }")
    end
                                        
    GL.ShaderSource(glsl_fragment_shader, 
                    File.read("./common/#{shader_base_file_name}.fsh"))

    # Compile shaders

    GL.CompileShader(glsl_vertex_shader)
    GL.CompileShader(glsl_fragment_shader)

    shaderCompiled = GL.GetShaderiv(glsl_vertex_shader, GL::COMPILE_STATUS)
    puts "VShader InfoLog:\n#{glGetShaderInfoLog(glsl_vertex_shader)}\n" if not shaderCompiled
    
    shaderCompiled = GL.GetShaderiv(glsl_fragment_shader, GL::COMPILE_STATUS)
    puts "FShader InfoLog:\n#{glGetShaderInfoLog(glsl_fragment_shader)}\n" if not shaderCompiled
    

    # Attach the shaders to the program
    GL.AttachShader(glsl_program, glsl_vertex_shader)
    GL.AttachShader(glsl_program, glsl_fragment_shader)

    # Link the program
    GL.LinkProgram(glsl_program)
    
    # Cleanup the shaders, the program copied them so they aren't needed anymore
    GL.DeleteShader(glsl_vertex_shader)
    GL.DeleteShader(glsl_fragment_shader)
    
    # Pass the GLSL program back to the caller
    @shaderProgram = glsl_program
  end
  
  def apply
    begin
      GL.UseProgram(@shaderProgram) if @shaderProgram
    rescue GL::Error => err
      p err
      @shaderProgram = nil
    end
  end
  
  def unload
    GL.UseProgram(0)
  end
  
  def set_uniform1i(name, i)
    p i
    if (@shaderProgram) then
      id = GL.GetUniformLocation(@shaderProgram, name);
      GL.Uniform1i(id,i) if (id != -1)
    end
  end
  
  def set_uniform1f(name, v)
    if (@shaderProgram) then
      id = GL.GetUniformLocation(@shaderProgram, name);
      GL.Uniform1f(id,v) if (id != -1)
    end
  end
  
  def set_uniform1fv(name, fv, size)
    if (@shaderProgram) then
      id = GL.GetUniformLocation(@shaderProgram, name);
      GL.Uniform1fv(id,size,fv) if (id != -1)
    end
  end
  
  def set_uniform2f(name, x, y)
    if (@shaderProgram) then
      id = GL.GetUniformLocation(@shaderProgram, name);
      GL.Uniform2f(id,x,y) if (id != -1)
    end
  end
  
end
