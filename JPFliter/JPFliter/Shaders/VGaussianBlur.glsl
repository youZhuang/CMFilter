//
//  HGaussianBlur.glsl.c
//  XBImageFilters
//
//  Created by xiss burg on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;

void main()
{
    vec4 color = vec4(0.0);
    
    color += texture2D(s_texture, vec2(v_texCoord.x, v_texCoord.y - 0.01  ))*0.05;
    color += texture2D(s_texture, vec2(v_texCoord.x, v_texCoord.y - 0.0075))*0.09;
    color += texture2D(s_texture, vec2(v_texCoord.x, v_texCoord.y - 0.005 ))*0.12;
    color += texture2D(s_texture, vec2(v_texCoord.x, v_texCoord.y - 0.0025))*0.15;
    color += texture2D(s_texture, vec2(v_texCoord.x, v_texCoord.y - 0.0   ))*0.16;
    color += texture2D(s_texture, vec2(v_texCoord.x, v_texCoord.y + 0.0025))*0.15;
    color += texture2D(s_texture, vec2(v_texCoord.x, v_texCoord.y + 0.005 ))*0.12;
    color += texture2D(s_texture, vec2(v_texCoord.x, v_texCoord.y + 0.0075))*0.09;
    color += texture2D(s_texture, vec2(v_texCoord.x, v_texCoord.y + 0.01  ))*0.05;
    
    gl_FragColor = color;
}