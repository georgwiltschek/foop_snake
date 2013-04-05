attribute vec4 pos;

// attribute vec4 gl_Color;
// 
varying vec4 gl_FrontColor; // writable on the vertex shader
// varying vec4 gl_BackColor; // writable on the vertex shader



void main() {
  gl_FrontColor = gl_Color;
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}