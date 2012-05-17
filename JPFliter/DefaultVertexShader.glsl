attribute vec4 a_position;
attribute vec2 a_texcoord;

uniform mat4 u_contentTransform;
uniform mat2 u_texCoordTransform

varying vec2 v_texcoord;

void main(){
    v_texcoord  = u_contentTransform * a_texcoord;
    gl_Position = u_texCoordTransform * a_position;
    //v_texcoord = a_texcoord;
    //gl_Position = a_position;
}