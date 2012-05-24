precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;

vec4 color[3];
float pi = 3.1415926;
const highp vec2 sampleDivisor = vec2(0.1, 0.1);

vec3 normalizeColor(vec3 color)
{
    return color / max(dot(color, vec3(1.0/3.0)), 0.3);
}

void main()
{
    //vec2 texcoord2 = vec2(abs(sin(texcoord2.x * pi * 2.0)),abs(cos(texcoord2.y * pi * 2.0)));
    
    /*
    *哈哈镜
    */
    //vec2 cen = vec2(0.5,0.5) - v_texCoord.xy;
    //vec2 mcen = -0.07 * log(length(cen)) * normalize(cen);

    //gl_FragColor = texture2D(s_texture, v_texCoord- mcen);
    
    /*
    *淡墨色特效
    *
    lowp vec4 textureColor = texture2D(s_texture, v_texCoord);
    lowp vec4 outputColor;
    outputColor.r = (textureColor.r * 0.393) + (textureColor.g * 0.769) + (textureColor.b * 0.189);
    outputColor.g = (textureColor.r * 0.349) + (textureColor.g * 0.686) + (textureColor.b * 0.168);    
    outputColor.b = (textureColor.r * 0.272) + (textureColor.g * 0.534) + (textureColor.b * 0.131);
    outputColor.a = 1.0;

    gl_FragColor = outputColor;*/
    
    /*
    *multi view
    */
    //highp vec2 samplePos = v_texCoord - mod(v_texCoord, sampleDivisor);
    //gl_FragColor = texture2D(s_texture, samplePos );
    
    /*
    *玻璃陈列馆效果
    *
    lowp vec3 tc = vec3(1.0, 0.0, 0.0);

    lowp vec3 pixcol = texture2D(s_texture, v_texCoord).rgb;
    lowp vec3 colors[3];
    colors[0] = vec3(0.0, 0.0, 1.0);
    colors[1] = vec3(1.0, 1.0, 0.0);
    colors[2] = vec3(1.0, 0.0, 0.0);
    mediump float lum = (pixcol.r + pixcol.g + pixcol.b) / 3.0;
    int ix = (lum < 0.5)? 0:1;
    tc = mix(colors[ix], colors[ix + 1], (lum - float(ix) * 0.5) / 0.5);

    gl_FragColor = vec4(tc, 1.0);*/
    
    vec4 p,calculatedColor,outputColor;
    p = texture2D(s_texture, v_texCoord);
    
    outputColor = vec4(normalizeColor(p.rgb),1.0);
    gl_FragColor = outputColor;
}