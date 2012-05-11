varying lowp vec4 DestinationColor;

varying lowp vec2 TexCoordOut; // New
uniform sampler2D Texture; // New

void main(void) {
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    yuv.x = texture2D(Texture, TexCoordOut).r;
    //yuv.yz = texture2D(SamplerUV, texCoordVarying).rg - vec2(0.5, 0.5);
    
    // BT.601, which is the standard for SDTV is provided as a reference
    /*
    rgb = mat3(    1,       1,     1,
                   0, -.34413, 1.772,
               1.402, -.71414,     0) * yuv;
     */
    
    // Using BT.709 which is the standard for HDTV
    rgb = mat3(      1,       1,      1,
                     0, -.18732, 1.8556,
               1.57481, -.46813,      0) * yuv;
    
    gl_FragColor = vec4(rgb, 1);
    //gl_FragColor = DestinationColor * texture2D(Texture, TexCoordOut); // New
}

