
precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;

void main()
{
    vec4 baseColor = texture2D(s_texture,v_texCoord);
    if(baseColor.r < 0.25){
        discard;
    }else{
        gl_FragColor = baseColor;
    }
}