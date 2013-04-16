varying vec4 frontColor;

void main() {
  frontColor = gl_Color;
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}