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

@property (nonatomic,retain) NSArray *programs;
@property (assign, nonatomic) CGSize contentSize;

@property (assign,nonatomic) BOOL isMultiTexture;

@property (nonatomic,assign) GLKMatrix4 contentTransform;
@property (nonatomic,assign) GLKMatrix2 texcoordTransform;

@property (readonly, nonatomic) GLint maxTextureSize; // Maximum texture width and height

-(void)render;

- (UIImage *)takeScreenshot;
- (UIImage *)takeScreenshotWithImageOrientation:(UIImageOrientation)orientation;

- (void)_setTextureData:(GLvoid *)textureData width:(GLint)width height:(GLint)height;
- (void)_updateTextureWithData:(GLvoid *)textureData;

-(BOOL)setFilterFragmentShaderFromFile:(NSString*)path error:(NSError *__autoreleasing *)error;
- (BOOL)setFilterFragmentShadersFromFiles:(NSArray *)paths error:(NSError *__autoreleasing *)error;

- (UIImage *)_filteredImageWithData:(GLvoid *)data textureWidth:(GLint)textureWidth textureHeight:(GLint)textureHeight targetWidth:(GLint)targetWidth targetHeight:(GLint)targetHeight contentTransform:(GLKMatrix4)contentTransform;
- (UIImage *)_imageFromFramebuffer:(GLuint)framebuffer width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation;
- (UIImage *)_imageWithData:(void *)data width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation ownsData:(BOOL)ownsData; // ownsData YES means the data buffer will be free()'d when the image is freed.

-(void) SafeReleasePixels;

@end
