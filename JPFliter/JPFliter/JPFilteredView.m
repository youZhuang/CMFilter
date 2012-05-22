//
//  JPFilteredView.m
//  JPFliter
//
//  Created by yiyang yuan on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JPFilteredView.h"
#import "QuartzCore/QuartzCore.h"
#import "GLKProgram.h"

const GLKMatrix2 GLKMatrix2Identity = {1,0,0,1};

typedef struct{
    GLKVector3 position;
    GLKVector2 texCoord;
} Vertex;

@interface JPFilteredView ()
{
    GLvoid *m_readPixels;
}

@property (nonatomic,strong) EAGLContext *context;
@property (nonatomic,assign) GLuint frameBuffer;
@property (nonatomic,assign) GLuint colorRenderBuffer;

@property (nonatomic,assign) GLint viewportWidth;
@property (nonatomic,assign) GLint viewportHeight;

@property (nonatomic,assign) CGRect previousBounds;

@property (nonatomic,assign) GLuint vertexBuffer;
@property (nonatomic,assign) GLuint indexBuffer;

@property (nonatomic,assign) GLuint texture;
@property (nonatomic,assign) GLuint texture2;

@property (nonatomic,assign) GLint textureWidth;
@property (nonatomic,assign) GLint textureHeight;

@property (nonatomic,assign) GLint texture2Width;
@property (nonatomic,assign) GLint texture2Height;

//@property (nonatomic,retain) GLKProgram *program;
@property (nonatomic,assign) GLKMatrix4 contentModeTransform;

/**
 * 支持多通道滤镜
 */
@property (assign, nonatomic) GLuint oddPassTexture;
@property (assign, nonatomic) GLuint evenPassTexture;
@property (assign, nonatomic) GLuint oddPassFramebuffer;
@property (assign, nonatomic) GLuint evenPassFrambuffer;

-(void)setDisplayLink;

-(void)setupGL;
-(void)destroyGL;
-(BOOL)createFrameBuffer;
-(void)destroyFrameBuffer;

- (void)setupEvenPass;
- (void)destroyEvenPass;
- (void)setupOddPass;
- (void)destroyOddPass;

- (void)refreshContentTransform;

- (GLKMatrix4)transformForAspectFitOrFill:(BOOL)fit;
- (GLKMatrix4)transformForPositionalContentMode:(UIViewContentMode)contentMode;

- (GLuint)generateDefaultTextureWithWidth:(GLint)width height:(GLint)height data:(GLvoid *)data;
- (GLuint)generateDefaultFramebufferWithTargetTexture:(GLuint)texture;

- (GLuint)setupTexture:(NSString *)fileName;
- (GLuint)setupSubTexture:(NSString *)fileName;

void ImageProviderReleaseData(void *info, const void *data, size_t size);

@end

@implementation JPFilteredView
@synthesize programs=_programs;
@synthesize contentSize =_contentSize;
@synthesize context = _context;
@synthesize frameBuffer = _frameBuffer;
@synthesize colorRenderBuffer = _colorRenderBuffer;

@synthesize viewportWidth = _viewportWidth;
@synthesize viewportHeight = _viewportHeight;

@synthesize previousBounds = _previousBounds;

@synthesize vertexBuffer = _vertexBuffer;
@synthesize indexBuffer = _indexBuffer;

@synthesize isMultiTexture = _isMultiTexture;
@synthesize texture = _texture;
@synthesize texture2 = _texture2;

@synthesize texture2Width = _texture2Width;
@synthesize texture2Height = _texture2Height;

@synthesize textureWidth = _textureWidth;
@synthesize textureHeight = _textureHeight;
@synthesize maxTextureSize = _maxTextureSize;

@synthesize contentTransform = _contentTransform;
@synthesize texcoordTransform = _texcoordTransform;

@synthesize contentModeTransform = _contentModeTransform;

@synthesize oddPassTexture = _oddPassTexture;
@synthesize evenPassTexture = _evenPassTexture;
@synthesize oddPassFramebuffer = _oddPassFramebuffer;
@synthesize evenPassFrambuffer = _evenPassFrambuffer;

//@synthesize program = _program;

-(void) _JPFilterViewInit
{
    self.contentScaleFactor = [[UIScreen mainScreen] scale];
    self.layer.opaque = YES;
    
    self.contentMode = UIViewContentModeScaleToFill;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (self.context == nil) {
        NSLog(@"context init faild!");
    }
    
    self.previousBounds = CGRectZero;
    
    if (!CGSizeEqualToSize(self.previousBounds.size,self.bounds.size)) {
        [self createFrameBuffer];
        self.previousBounds = self.bounds;
    }
    
    
    
    [self setupGL];

    [self setDisplayLink];
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self _JPFilterViewInit];
    }
    return self;
}

-(void)awakeFromNib
{
    [self _JPFilterViewInit];
}

-(void)dealloc
{
    [EAGLContext setCurrentContext:self.context];
    [self destroyGL];
    [EAGLContext setCurrentContext:nil];
    [super dealloc];
}

#pragma mark --
#pragma mark layer and view overides

+(Class)layerClass
{
    return [CAEAGLLayer class];
}

-(void)layoutSubviews
{
    if (!CGSizeEqualToSize(self.previousBounds.size,self.bounds.size)) {
        [self createFrameBuffer];
    }
    self.previousBounds = self.bounds;
    
    [self refreshContentTransform];
    
    [self render];
}

#pragma mark - Properties

- (void)setContentTransform:(GLKMatrix4)contentTransform
{
    _contentTransform = contentTransform;
    [self refreshContentTransform];
}

- (void)setContentModeTransform:(GLKMatrix4)contentModeTransform
{
    _contentModeTransform = contentModeTransform;
    [self refreshContentTransform];
}

- (void)setContentSize:(CGSize)contentSize
{
    _contentSize = contentSize;
    [self refreshContentTransform];
}

- (void)setTexCoordTransform:(GLKMatrix2)texCoordTransform
{
    _texcoordTransform = texCoordTransform;
    
    // The transform is applied only on the first program, because the next ones will already receive and image with the transform applied.
    // The transform would be applied again on each filter otherwise.
    GLKProgram *firstProgram = [self.programs objectAtIndex:0];
    [firstProgram setValue:&texCoordTransform forUniformNamed:@"u_texCoordTransform"];
}

#pragma mark --
#pragma mark GL Set

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
};

-(void)setupGL
{
    NSLog(@"setup openGL ES");
    [EAGLContext setCurrentContext:self.context];
    
    self.backgroundColor = self.backgroundColor;
    
    //glDisable(GL_DEPTH_TEST);
    
    int TEX_COORD_MAX = 1;
    
    /*
    Vertex vertices[] = {
        {{ 1,  1, 0}, {1, 1}},
        {{-1,  1, 0}, {0, 1}},
        {{ 1, -1, 0}, {1, 0}},
        {{-1, -1, 0}, {0, 0}}
    };*/
    
    
    const Vertex vertices[] = {
        // Front
        {{1, -1, 0}, {TEX_COORD_MAX, 0}},
        {{1, 1, 0}, {TEX_COORD_MAX, TEX_COORD_MAX}},
        {{-1, 1, 0},  {0, TEX_COORD_MAX}},
        {{-1, -1, 0}, {0, 0}},
    };
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    //configure the shader compiler
    
    //[self compileShaders];
    
    NSString *fragmentPath = [[NSBundle mainBundle] pathForResource:@"DefaultFragmentShader" ofType:@"glsl"];
    NSError *error = nil;
    [self setFilterFragmentShaderFromFile:fragmentPath error:&error];
    if (error != nil) {
        NSLog(@"configure shader error :%@",[error localizedDescription]);
    }
    self.contentModeTransform = GLKMatrix4MakeOrtho(-1.f, 1.f, -1.f, 1.f, -1.f, 1.f);
    self.contentTransform = GLKMatrix4Identity;
    self.texcoordTransform = GLKMatrix2Identity;
    
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, &_maxTextureSize);
}

-(void)destroyGL
{
    NSLog(@"destroy openGL ES");
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteTextures(1, &_texture);
    
    glDeleteTextures(1, &_evenPassTexture);
    glDeleteTextures(1, &_oddPassTexture);
    
    glDeleteFramebuffers(1, &_evenPassFrambuffer);
    glDeleteFramebuffers(1, &_oddPassFramebuffer);
    
    glDeleteBuffers(1, &_vertexBuffer);
    self.vertexBuffer = 0;
    
    [self destroyFrameBuffer];
}

-(BOOL)createFrameBuffer
{
    NSLog(@"create frame buffer");
    
    [EAGLContext setCurrentContext:self.context];
    
    [self destroyFrameBuffer];
    
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBuffer);
    
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorRenderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.colorRenderBuffer);
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_viewportWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_viewportHeight);
    
    NSLog(@"%@,%d,%d",NSStringFromSelector(_cmd),_viewportWidth,_viewportHeight);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"gl faild create frame buffer status :%d",status);
        return NO;
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorRenderBuffer);
    
    return YES;
}

-(void)destroyFrameBuffer
{
    glDeleteFramebuffers(1, &_frameBuffer);
    self.frameBuffer = 0;
    
    glDeleteRenderbuffers(1, &_colorRenderBuffer);
    self.colorRenderBuffer = 0;
    
}

- (void)refreshContentTransform
{
    GLKMatrix4 composedTransform = GLKMatrix4Multiply(self.contentTransform, self.contentModeTransform);
    
    // The contentTransform is only applied on the last program otherwise it would be reapplied in each filter. Also, the contentTransform's
    // purpose is to adjust the final image on the framebuffer/screen. That is why it is applied only in the end.
    GLKProgram *lastProgram = [self.programs lastObject];
    [lastProgram setValue:composedTransform.m forUniformNamed:@"u_contentTransform"];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    [EAGLContext setCurrentContext:self.context];
    CGFloat r, g, b, a;
    [self.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
    glClearColor(r, g, b, a);
}

-(void)setDisplayLink{
    //CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    //[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

//static NSInteger framecount = 0;

-(void)render
{
    if (_isMultiTexture) {
        //glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        //glEnable(GL_BLEND);
    }else {
        glDisable(GL_BLEND);
    }
   // NSLog(@"render ...");
    [EAGLContext setCurrentContext:self.context];
    
    for (int pass = 0; pass < self.programs.count; ++pass) {
        GLKProgram *program = [self.programs objectAtIndex:pass];
        
        if (pass == self.programs.count - 1) { // Last pass, bind screen framebuffer
            glViewport(0, 0, self.viewportWidth, self.viewportHeight);
            glBindFramebuffer(GL_FRAMEBUFFER, self.frameBuffer);
        }
        else if (pass%2 == 0) {
            glViewport(0, 0, self.textureWidth, self.textureHeight);
            glBindFramebuffer(GL_FRAMEBUFFER, self.evenPassFrambuffer);
        }
        else {
            glViewport(0, 0, self.textureWidth, self.textureHeight);
            glBindFramebuffer(GL_FRAMEBUFFER, self.oddPassFramebuffer);
        }
        
        glClear(GL_COLOR_BUFFER_BIT);
        
        [program prepareToDraw];
        
        glDrawElements(GL_TRIANGLES, sizeof(Indices)/(sizeof(Indices[0])), GL_UNSIGNED_BYTE, 0);
        
        // If it is not the last pass, discard the framebuffer contents
        if (pass != self.programs.count - 1) {
            const GLenum discards[] = {GL_COLOR_ATTACHMENT0};
            glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
        }
    }
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
#ifdef DEBUG
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"%d", error);
    }
#endif
}

- (UIImage *)takeScreenshot
{
    return [self takeScreenshotWithImageOrientation:UIImageOrientationDownMirrored];
}

- (UIImage *)takeScreenshotWithImageOrientation:(UIImageOrientation)orientation
{
    int width = (int)(self.bounds.size.width * self.contentScaleFactor);
    int height = (int)(self.bounds.size.height * self.contentScaleFactor);
    return [self _imageFromFramebuffer:self.frameBuffer width:width height:height orientation:orientation];
}

- (UIImage *)_filteredImageWithData:(GLvoid *)data textureWidth:(GLint)textureWidth textureHeight:(GLint)textureHeight targetWidth:(GLint)targetWidth targetHeight:(GLint)targetHeight contentTransform:(GLKMatrix4)contentTransform
{
    [EAGLContext setCurrentContext:self.context];
    
    GLKMatrix4 oldContentTransform = self.contentTransform;
    self.contentTransform = contentTransform;
    UIViewContentMode oldContentMode = self.contentMode;
    self.contentMode = UIViewContentModeScaleToFill;
    
    GLuint mainTexture = [self generateDefaultTextureWithWidth:textureWidth height:textureHeight data:data];
    GLuint evenPassTexture = [self generateDefaultTextureWithWidth:targetWidth height:targetHeight data:NULL];
    GLuint evenPassFrambuffer = [self generateDefaultFramebufferWithTargetTexture:evenPassTexture];
    GLuint oddPassTexture = 0;
    GLuint oddPassFramebuffer = 0;
    
    if (self.programs.count > 1) {
        oddPassTexture = [self generateDefaultTextureWithWidth:targetWidth height:targetHeight data:NULL];
        oddPassFramebuffer = [self generateDefaultFramebufferWithTargetTexture:oddPassTexture];
    }
    
    GLuint lastFramebuffer = 0;
    
    glViewport(0, 0, targetWidth, targetHeight);
    
    for (int pass = 0; pass < self.programs.count; ++pass) {
        GLKProgram *program = [self.programs objectAtIndex:pass];
        
        if (pass%2 == 0) {
            glBindFramebuffer(GL_FRAMEBUFFER, evenPassFrambuffer);
            lastFramebuffer = evenPassFrambuffer;
        }
        else {
            glBindFramebuffer(GL_FRAMEBUFFER, oddPassFramebuffer);
            lastFramebuffer = oddPassFramebuffer;
        }
        
        // Change the source texture for each pass
        GLuint sourceTexture = 0;
        
        if (pass == 0) { // First pass always uses the original image
            sourceTexture = mainTexture;
        }
        else if (pass%2 == 1) { // Second pass uses the result of the first, and the first is 0, hence even
            sourceTexture = evenPassTexture;
        }
        else { // Third pass uses the result of the second, which is number 1, then it's odd
            sourceTexture = oddPassTexture;
        }
        
        [program bindSamplerNamed:@"s_texture" toTexture:sourceTexture unit:0];
        
        glClear(GL_COLOR_BUFFER_BIT);
        
        [program prepareToDraw];
        
        //glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glDrawElements(GL_TRIANGLES, sizeof(Indices)/(sizeof(Indices[0])), GL_UNSIGNED_BYTE, 0);
        
        // If it is not the last pass, discard the framebuffer contents
        if (pass != self.programs.count - 1) {
            const GLenum discards[] = {GL_COLOR_ATTACHMENT0};
            glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
        }
    }
    
    UIImage *image = [self _imageFromFramebuffer:lastFramebuffer width:targetWidth height:targetHeight orientation:UIImageOrientationUp];
    
    NSLog(@"filteredImage :%@",NSStringFromCGSize(image.size));
//    if (_isMultiTexture) {
//        GLuint secondFrameBuffer = [self generateDefaultFramebufferWithTargetTexture:self.texture2];
//        UIImage *secondImage = [self _imageFromFramebuffer:secondFrameBuffer width:targetWidth height:targetHeight orientation:UIImageOrientationLeft];
//        NSLog(@"secondImage size :%@",NSStringFromCGSize(secondImage.size));
//    }
    
    // Now discard the lastFramebuffer
    const GLenum discards[] = {GL_COLOR_ATTACHMENT0};
    glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
    
    // Reset texture bindings
    for (int pass = 0; pass < self.programs.count; ++pass) {
        GLKProgram *program = [self.programs objectAtIndex:pass];
        GLuint sourceTexture = 0;
        
        if (pass == 0) { // First pass always uses the original image
            sourceTexture = self.texture;
        }
        else if (pass%2 == 1) { // Second pass uses the result of the first, and the first is 0, hence even
            sourceTexture = self.evenPassTexture;
        }
        else { // Third pass uses the result of the second, which is number 1, then it's odd
            sourceTexture = self.oddPassTexture;
        }
        
        [program bindSamplerNamed:@"s_texture" toTexture:sourceTexture unit:0];
    }
    
    glDeleteTextures(1, &mainTexture);
    glDeleteTextures(1, &evenPassTexture);
    glDeleteFramebuffers(1, &evenPassFrambuffer);
    glDeleteTextures(1, &oddPassTexture);
    glDeleteFramebuffers(1, &oddPassFramebuffer);
    
    self.contentTransform = oldContentTransform;
    self.contentMode = oldContentMode;
    
#ifdef DEBUG
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"%d", error);
    }
#endif
    
    return image;
}

- (UIImage *)_imageFromFramebuffer:(GLuint)framebuffer width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation
{
    [EAGLContext setCurrentContext:self.context];
    
    assert(!m_readPixels);
    
    size_t size = width * height * 4;
    m_readPixels = malloc(size);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, m_readPixels);
    
    return [self _imageWithData:m_readPixels width:width height:height orientation:orientation ownsData:YES];
}

- (UIImage *)_imageWithData:(void *)data width:(GLint)width height:(GLint)height orientation:(UIImageOrientation)orientation ownsData:(BOOL)ownsData
{
    size_t size = width * height * 4;
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = width * bitsPerPixel / bitsPerComponent;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, size, ownsData?ImageProviderReleaseData : NULL);
    CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, provider, NULL, FALSE, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:self.contentScaleFactor orientation:orientation];
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

- (GLuint)setupTexture:(NSString *)fileName {
    
    // 1
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData); 

    return texName;
    
}

- (void)setupEvenPass
{
    self.evenPassTexture = [self generateDefaultTextureWithWidth:self.textureWidth height:self.textureHeight data:NULL];
    self.evenPassFrambuffer = [self generateDefaultFramebufferWithTargetTexture:self.evenPassTexture];
}

- (void)destroyEvenPass
{
    glDeleteTextures(1, &_evenPassTexture);
    self.evenPassTexture = 0;
    glDeleteFramebuffers(1, &_evenPassFrambuffer);
    self.evenPassFrambuffer = 0;
}

- (void)setupOddPass
{
    self.oddPassTexture = [self generateDefaultTextureWithWidth:self.textureWidth height:self.textureHeight data:NULL];
    self.oddPassFramebuffer = [self generateDefaultFramebufferWithTargetTexture:self.oddPassTexture];
}

- (void)destroyOddPass
{
    glDeleteTextures(1, &_oddPassTexture);
    self.oddPassTexture = 0;
    glDeleteFramebuffers(1, &_oddPassFramebuffer);
    self.oddPassFramebuffer = 0;
}

- (GLuint)generateDefaultTextureWithWidth:(GLint)width height:(GLint)height data:(GLvoid *)data
{
    GLuint texture = 0;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, data);
    glBindTexture(GL_TEXTURE_2D, 0);
    return texture;
}

- (GLuint)generateDefaultFramebufferWithTargetTexture:(GLuint)texture
{
    GLuint framebuffer = 0;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    return framebuffer;
}

- (void)_setTextureData:(GLvoid *)textureData width:(GLint)width height:(GLint)height
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteTextures(1, &_texture);
    
    [self destroyOddPass];
    [self destroyEvenPass];
    
    self.textureWidth = width;
    self.textureHeight = height;
    self.texture = [self generateDefaultTextureWithWidth:self.textureWidth height:self.textureHeight data:textureData];
    
    if (self.programs.count >= 2) {
        [self setupEvenPass];
    }
    
    if (self.programs.count > 2) {
        [self setupOddPass];
    }
    
    if (self.programs.count > 0) {
        GLKProgram *firstProgram = [self.programs objectAtIndex:0];
        [firstProgram bindSamplerNamed:@"s_texture" toTexture:self.texture unit:0];
    }
    
    // Force an update on the contentTransform since it depends on the textureWidth and textureHeight
    [self setNeedsLayout];
}

- (void)_updateTextureWithData:(GLvoid *)textureData
{
    [EAGLContext setCurrentContext:self.context];
    
    glBindTexture(GL_TEXTURE_2D, self.texture);
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, self.textureWidth, self.textureHeight, GL_BGRA, GL_UNSIGNED_BYTE, textureData);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    [self render];
}

#pragma mark - Public Methods

- (BOOL)setFilterFragmentShaderFromFile:(NSString *)path error:(NSError *__autoreleasing *)error
{
    NSArray *paths = [NSArray arrayWithObjects:path, nil];
    return [self setFilterFragmentShadersFromFiles:paths error:error];
}

- (BOOL)setFilterFragmentShadersFromFiles:(NSArray *)paths error:(NSError *__autoreleasing *)error
{
    [EAGLContext setCurrentContext:self.context];
    
    [self destroyEvenPass];
    [self destroyOddPass];
    
    /* Create frame buffers for render to texture in multi-pass filters if necessary. If we have a single pass/fragment shader, we'll render
     * directly to the framebuffer. If we have two passes, we'll render to the evenPassFramebuffer using the original image as the filter source
     * texture and then render directly to the framebuffer using the evenPassTexture as the filter source. If we have three passes, the second
     * filter will instead render to the oddPassFramebuffer and the third/last pass will render to the framebuffer using the oddPassTexture.
     * And so on... */
    
    if (paths.count >= 2) {
        // Two or more passes, create evenPass*
        [self setupEvenPass];
    }
    
    if (paths.count > 2) {
        // More than two passes, create oddPass*
        [self setupOddPass];
    }
    
    NSMutableArray *programs = [[NSMutableArray alloc] initWithCapacity:paths.count];
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"DefaultVertexShader" ofType:@"glsl"];
    
    for (int i = 0; i < paths.count; ++i) {
        NSString *fragmentShaderPath = [paths objectAtIndex:i];
        GLKProgram *program = [[GLKProgram alloc] initWithVertexShaderFromFile:vertexShaderPath fragmentShaderFromFile:fragmentShaderPath error:error];
        
        if (program == nil) {
            return NO;
        }
        
        [program setValue:i == paths.count - 1?&_contentTransform: (void *)&GLKMatrix4Identity forUniformNamed:@"u_contentTransform"];
        [program setValue:i == 0?&_texcoordTransform: (void *)&GLKMatrix2Identity forUniformNamed:@"u_texCoordTransform"];
        
        GLuint sourceTexture = 0;
        
        if (i == 0) { // First pass always uses the original image
            sourceTexture = self.texture;
        }
        else if (i%2 == 1) { // Second pass uses the result of the first, and the first is 0, hence even
            sourceTexture = self.evenPassTexture;
        }
        else { // Third pass uses the result of the second, which is number 1, then it's odd
            sourceTexture = self.oddPassTexture;
        }
        
        [program bindSamplerNamed:@"s_texture" toTexture:sourceTexture unit:0];
        
        // Enable vertex position and texCoord attributes
        GLKAttribute *positionAttribute = [program.attributes objectForKey:@"a_position"];
        glVertexAttribPointer(positionAttribute.location, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, position));
        glEnableVertexAttribArray(positionAttribute.location);
        
        GLKAttribute *texCoordAttribute = [program.attributes objectForKey:@"a_texCoord"];
        glVertexAttribPointer(texCoordAttribute.location, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, texCoord));
        glEnableVertexAttribArray(texCoordAttribute.location);
        
        [programs addObject:program];
        [program release];
    }
    
    self.programs = [programs copy];
    
    [programs release];
    
    if (_isMultiTexture) {
        glDeleteTextures(1, &_texture2);
        _texture2 = [self setupTexture:@"test2.png"];
        if (self.programs.count > 0) {
            GLKProgram *firstProgram = [self.programs objectAtIndex:0];
            [firstProgram bindSamplerNamed:@"s_texture2" toTexture:self.texture2 unit:1];
        }
    }
    
    [self setNeedsLayout];
    
    return YES;
}

- (GLKMatrix4)transformForAspectFitOrFill:(BOOL)fit
{
    float imageAspect = (float)self.contentSize.width/self.contentSize.height;
    float viewAspect = self.bounds.size.width/self.bounds.size.height;
    GLKMatrix4 transform;
    
    if ((imageAspect > viewAspect && fit) || (imageAspect < viewAspect && !fit)) {
        transform = GLKMatrix4MakeOrtho(-1, 1, -imageAspect/viewAspect, imageAspect/viewAspect, -1, 1);
    }
    else {
        transform = GLKMatrix4MakeOrtho(-viewAspect/imageAspect, viewAspect/imageAspect, -1, 1, -1, 1);
    }
    
    return transform;
}

- (GLKMatrix4)transformForPositionalContentMode:(UIViewContentMode)contentMode
{
    float widthRatio = self.bounds.size.width/self.contentSize.width*self.contentScaleFactor;
    float heightRatio = self.bounds.size.height/self.contentSize.height*self.contentScaleFactor;
    GLKMatrix4 transform = GLKMatrix4Identity;
    
    switch (contentMode) {
        case UIViewContentModeCenter:
            transform = GLKMatrix4MakeOrtho(-widthRatio, widthRatio, -heightRatio, heightRatio, -1, 1);
            break;
            
        case UIViewContentModeBottom:
            transform = GLKMatrix4MakeOrtho(-widthRatio, widthRatio, -1, 2*heightRatio - 1, -1, 1);
            break;
            
        case UIViewContentModeTop:
            transform = GLKMatrix4MakeOrtho(-widthRatio, widthRatio, -2*heightRatio + 1, 1, -1, 1);
            break;
            
        case UIViewContentModeLeft:
            transform = GLKMatrix4MakeOrtho(-1, 2*widthRatio - 1, -heightRatio, heightRatio, -1, 1);
            break;
            
        case UIViewContentModeRight:
            transform = GLKMatrix4MakeOrtho(-2*widthRatio + 1, 1, -heightRatio, heightRatio, -1, 1);
            break;
            
        case UIViewContentModeTopLeft:
            transform = GLKMatrix4MakeOrtho(-1, 2*widthRatio - 1, -2*heightRatio + 1, 1, -1, 1);
            break;
            
        case UIViewContentModeTopRight:
            transform = GLKMatrix4MakeOrtho(-2*widthRatio + 1, 1, -2*heightRatio + 1, 1, -1, 1);
            break;
            
        case UIViewContentModeBottomLeft:
            transform = GLKMatrix4MakeOrtho(-1, 2*widthRatio - 1, -1, 2*heightRatio - 1, -1, 1);
            break;
            
        case UIViewContentModeBottomRight:
            transform = GLKMatrix4MakeOrtho(-2*widthRatio + 1, 1, -1, 2*heightRatio - 1, -1, 1);
            break;
            
        default:
            NSLog(@"Warning: Invalid contentMode given to transformForPositionalContentMode: %d", contentMode);
            break;
    }
    
    return transform;
}

void ImageProviderReleaseData(void *info, const void* data, size_t size)
{
    free((void *)data);
}

-(void) SafeReleasePixels
{
    free((void *)m_readPixels);
    m_readPixels = nil;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


@end
