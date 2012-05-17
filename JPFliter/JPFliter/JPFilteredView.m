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
    GLuint _positionSlot;
    
    GLuint _texCoordSlot;
    GLuint _textureUniform;

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

@property (nonatomic,assign) GLint textureWidth;
@property (nonatomic,assign) GLint textureHeight;
@property (nonatomic,assign) GLint maxTextureSize;

@property (nonatomic,retain) GLKProgram *program;



@property (nonatomic,assign) GLKMatrix4 contentModeTransform; 

-(void)setDisplayLink;

-(void)setupGL;
-(void)destroyGL;
-(BOOL)createFrameBuffer;
-(void)destroyFrameBuffer;

- (void)refreshContentTransform;

- (GLuint)generateDefaultTextureWithWidth:(GLint)width height:(GLint)height data:(GLvoid *)data;
- (GLuint)generateDefaultFramebufferWithTargetTexture:(GLuint)texture;



- (GLuint)setupTexture:(NSString *)fileName;

@end

@implementation JPFilteredView
@synthesize context = _context;
@synthesize frameBuffer = _frameBuffer;
@synthesize colorRenderBuffer = _colorRenderBuffer;

@synthesize viewportWidth = _viewportWidth;
@synthesize viewportHeight = _viewportHeight;

@synthesize previousBounds = _previousBounds;

@synthesize vertexBuffer = _vertexBuffer;
@synthesize indexBuffer = _indexBuffer;
@synthesize texture = _texture;
@synthesize textureWidth = _textureWidth;
@synthesize textureHeight = _textureHeight;
@synthesize maxTextureSize = _maxTextureSize;

@synthesize contentTransform = _contentTransform;
@synthesize texcoordTransform = _texcoordTransform;

@synthesize contentModeTransform = _contentModeTransform;

@synthesize program = _program;

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
    //composedTransform = GLKMatrix4Multiply(composedTransform, projection);
    [self.program setValue:composedTransform.m forUniformNamed:@"u_contentTransform"];
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
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

-(void)render
{
   // NSLog(@"render ...");
    [EAGLContext setCurrentContext:self.context];
    
    glViewport(0, 0, self.textureWidth *4, self.textureHeight * 4);
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBuffer);
    
    
    glClearColor(0.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [_program prepareToDraw];
    
    //glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
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
    
    self.textureWidth = width;
    self.textureHeight = height;
    
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
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData); 

    return texName;
    
}

-(BOOL)setFilterFragmentShaderFromFile:(NSString *)path error:(NSError **)error
{
    [EAGLContext setCurrentContext:self.context];
    
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"DefaultVertexShader" ofType:@"glsl"];
    
    _program = [[GLKProgram alloc] initWithVertexShaderFromFile:vertexShaderPath fragmentShaderFromFile:path error:error];
    if (_program == nil) {
        return NO;
    }
    [_program setValue:&_contentTransform forUniformNamed:@"u_contentTransform"];
    [_program setValue:&GLKMatrix2Identity forUniformNamed:@"u_texCoordTransform"];
    
    _texture = [self setupTexture:@"tile_floor.png"];
    
    GLuint _subTexture = [self setupTexture:@"test.png"];
    
    [_program bindSamplerNamed:@"texture" toTexture:_texture unit:0];
    
    [_program bindSamplerNamed:@"subtexture" toTexture:_subTexture unit:0];
    
    GLKAttribute *positionAttribute = [_program.attributes objectForKey:@"a_position"];
    //_positionSlot = glGetAttribLocation(_program.program, "a_position");
    glVertexAttribPointer(positionAttribute.location, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*)offsetof(Vertex, position));
    glEnableVertexAttribArray(positionAttribute.location);
    
    GLKAttribute *texcoordAttribute = [_program.attributes objectForKey:@"a_texCoord"];
    //_texCoordSlot = glGetAttribLocation(_program.program, "a_texCoord");
    glVertexAttribPointer(texcoordAttribute.location, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid*)offsetof(Vertex, texCoord));
    glEnableVertexAttribArray(texcoordAttribute.location);
    
    //[self setNeedsLayout];
    
    return YES;
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
