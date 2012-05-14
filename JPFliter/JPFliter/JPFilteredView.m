//
//  JPFilteredView.m
//  JPFliter
//
//  Created by yiyang yuan on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JPFilteredView.h"
#import "QuartzCore/QuartzCore.h"

const GLKMatrix2 MLKMatrix2Identity = {1,0,0,1};

typedef struct{
    GLKVector3 position;
    GLKVector2 texCoord;
} Vertex;

@interface JPFilteredView ()

@property (nonatomic,strong) EAGLContext *context;
@property (nonatomic,assign) GLint frameBuffer;
@property (nonatomic,assign) GLint colorRenderBuffer;

@property (nonatomic,assign) GLint viewportWidth;
@property (nonatomic,assign) GLint viewportHeight;

@property (nonatomic,assign) CGRect previousBounds;

@property (nonatomic,assign) GLint vertexBuffer;
@property (nonatomic,assign) GLint textureWidth;
@property (nonatomic,assign) GLint textureHeight;
@property (nonatomic,assign) GLint texture;


-(void)setupGL;
-(void)destroyGL;
-(void)createFrameBuffer;

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
@synthesize texture = _texture;
@synthesize textureWidth = _textureWidth;
@synthesize textureHeight = _textureHeight;

-(void) _JPFilterViewInit
{
    self.contentScaleFactor = [[UIScreen mainScreen] scale];
    self.layer.opaque = YES;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.previousBounds = CGRectZero;
    
    if (CGSizeEqualToSize(self.previousBounds.size,self.bounds.size)) {
        [self createFrameBuffer];
        self.previousBounds = self.bounds;
    }
    
    [self setupGL];
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

-(void)setupGL
{
    NSLog(@"setup openGL ES");
}

-(void)destroyGL
{
    NSLog(@"destroy openGL ES");
}

-(void)createFrameBuffer
{
    
}

-(void)render
{
    NSLog(@"render ...");
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
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    //glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_BGRA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);        
    return texName;
    
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
