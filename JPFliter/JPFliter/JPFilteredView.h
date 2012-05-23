//
//  JPFilteredView.h
//  JPFliter
//
//  Created by yiyang yuan on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

extern const GLKMatrix2 GLKMatrix2Identity;

@interface JPFilteredView : UIView

@property (nonatomic,retain) NSArray *programs;//保存所有的着色器
@property (assign, nonatomic) CGSize contentSize;//显示的像素尺寸

@property (assign,nonatomic) BOOL isMultiTexture;//支持多张贴图混合

@property (nonatomic,assign) GLKMatrix4 contentTransform;//定点坐标矩阵
@property (nonatomic,assign) GLKMatrix2 texcoordTransform;//贴图坐标矩阵

@property (readonly, nonatomic) GLint maxTextureSize; //设备支持的最大贴图宽和高

-(void)render;

//如果有混合贴图，可调用以下两个函数
- (UIImage *)takeScreenshot;
- (UIImage *)takeScreenshotWithImageOrientation:(UIImageOrientation)orientation;

- (void)_setTextureData:(GLvoid *)textureData width:(GLint)width height:(GLint)height;
- (void)_updateTextureWithData:(GLvoid *)textureData;

//加载滤镜的片段着色器的资源
-(BOOL)setFilterFragmentShaderFromFile:(NSString*)path error:(NSError *__autoreleasing *)error;
- (BOOL)setFilterFragmentShadersFromFiles:(NSArray *)paths error:(NSError *__autoreleasing *)error;

//获得当前帧下的一张image
- (UIImage *)_filteredImageWithData:(GLvoid *)data textureWidth:(GLint)textureWidth textureHeight:(GLint)textureHeight targetWidth:(GLint)targetWidth targetHeight:(GLint)targetHeight contentTransform:(GLKMatrix4)contentTransform;
- (UIImage *)_imageFromFramebuffer:(GLuint)framebuffer width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation;
- (UIImage *)_imageWithData:(void *)data width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation ownsData:(BOOL)ownsData; //auto free the pixelData

//当生成image后，安全释放像素内存
-(void) SafeReleasePixels;

@end
