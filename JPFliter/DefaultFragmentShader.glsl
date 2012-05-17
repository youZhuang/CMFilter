uniform sampler2D s_texture;

varying vec2 v_texcoord;

void main(){
    gl_FragColor = Texture2D(s_texture,v_texcoord);
}