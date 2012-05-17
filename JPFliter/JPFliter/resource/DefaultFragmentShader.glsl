//
//  DefaultFragmentShader.glsl.c
//  XBImageFilters
//
//  Created by xiss burg on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


precision mediump float;

uniform sampler2D texture;
uniform sampler2D subtexture;

varying vec2 v_texCoord;

void main()
{
    gl_FragColor = texture2D(texture, v_texCoord);
    //gl_FragColor = vec4(0.5,0.5,0.0,1.0);
}