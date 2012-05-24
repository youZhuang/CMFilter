precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;

void main()
{
    /*
    *玻璃陈列馆效果
    */
    lowp vec3 tc = vec3(1.0, 0.0, 0.0);

    lowp vec3 pixcol = texture2D(s_texture, v_texCoord).rgb;
    lowp vec3 colors[3];
    colors[0] = vec3(0.0, 0.0, 1.0);
    colors[1] = vec3(1.0, 1.0, 0.0);
    colors[2] = vec3(1.0, 0.0, 0.0);
    mediump float lum = (pixcol.r + pixcol.g + pixcol.b) / 3.0;
    int ix = (lum < 0.5)? 0:1;
    tc = mix(colors[ix], colors[ix + 1], (lum - float(ix) * 0.5) / 0.5);

    gl_FragColor = vec4(tc, 1.0);
}