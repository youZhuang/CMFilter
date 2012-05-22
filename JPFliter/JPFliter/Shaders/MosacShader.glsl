//
//  ViewController.h
//  JPFliter
//
//  Created by yiyang yuan on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;


void main()
{
    vec2 mosaicSize = vec2(8,8);
    vec2 TexSize = vec2(640,852);
    //得到当前纹理坐标相对图像大小的整数值
    float intx = v_texCoord.x * TexSize.x;
    float inty = v_texCoord.y * TexSize.y;
    vec2 xy = vec2(intx,inty);
    
    //根据马赛克快的大小进行取整
    int mox = int(xy.x/mosaicSize.x) * int(mosaicSize.x);
    int moy = int(xy.y/mosaicSize.y) * int(mosaicSize.y);
    vec2 xyMosaic = vec2(mox,moy);
    //把整数坐标转换回纹理采样坐标
    vec2 UVMosaic = vec2(xyMosaic.y/TexSize.x,xyMosaic.y/TexSize.y);
    gl_FragColor = texture2D(s_texture,UVMosaic);
}