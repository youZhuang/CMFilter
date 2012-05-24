precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;

void main()
{
    /*
    *哈哈镜
    */
    vec2 cen = vec2(0.5,0.5) - v_texCoord.xy;
    vec2 mcen = -0.07 * log(length(cen)) * normalize(cen);

    gl_FragColor = texture2D(s_texture, v_texCoord- mcen);
}