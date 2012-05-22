
precision mediump float;

varying vec2 v_texCoord;

uniform sampler2D s_texture,s_texture2;

void main()
{
    vec4 baseColor;
    vec4 secondColor;
    
    baseColor = texture2D(s_texture,v_texCoord);
    secondColor = texture2D(s_texture2,v_texCoord);
    gl_FragColor = baseColor * (secondColor + 0.25);
}