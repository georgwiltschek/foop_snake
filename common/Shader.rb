class Shader
  
  @shaderProgram = nil
  
  def initialize shader_base_file_name
    # Create GLSL program and shader objects
    glsl_program = GL.CreateProgram()
    glsl_vertex_shader = GL.CreateShader(GL_VERTEX_SHADER)
    glsl_fragment_shader = GL.CreateShader(GL_FRAGMENT_SHADER)

    # Load shader source into the shaders
    GL.ShaderSource(glsl_vertex_shader,
                    File.read(File.join(File.dirname(__FILE__), 
                                        "#{shader_base_file_name}.vsh")))
    GL.ShaderSource(glsl_fragment_shader, 
                    File.read(File.join(File.dirname(__FILE__), 
                                        "#{shader_base_file_name}.fsh")))

    # Compile shaders
    GL.CompileShader(glsl_vertex_shader)
    GL.CompileShader(glsl_fragment_shader)

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
    GL.UseProgram(@shaderProgram) if @shaderProgram
  end
end