precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;

void main()
{
    /*
    *淡墨色特效
    */
    lowp vec4 textureColor = texture2D(s_texture, v_texCoord);
    lowp vec4 outputColor;
    outputColor.r = (textureColor.r * 0.393) + (textureColor.g * 0.769) + (textureColor.b * 0.189);
    outputColor.g = (textureColor.r * 0.349) + (textureColor.g * 0.686) + (textureColor.b * 0.168);    
    outputColor.b = (textureColor.r * 0.272) + (textureColor.g * 0.534) + (textureColor.b * 0.131);
    outputColor.a = 1.0;

    gl_FragColor = outputColor;
    
}