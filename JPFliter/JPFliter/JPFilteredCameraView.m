//
//  JPFilteredCameraView.m
//  JPFliter
//
//  Created by yiyang yuan on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JPFilteredCameraView.h"

@interface JPFilteredCameraView ()

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (assign, nonatomic) size_t videoWidth, videoHeight;

-(void)initAVObjects;

-(void)setupOutput;
- (void)startCapturing;
- (void)stopCapturing;

@end

@implementation JPFilteredCameraView
@synthesize captureSession = _captureSession;
@synthesize device = _device;
@synthesize input = _input;
@synthesize videoDataOutput = _videoDataOutput;
@synthesize stillImageOutput = _stillImageOutput;
@synthesize videoWidth = _videoWidth, videoHeight = _videoHeight;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initAVObjects];
    }
    return self;
}

-(void)dealloc
{
    [self stopCapturing];
    [super dealloc];
}

-(void)initAVObjects
{
    self.videoWidth = self.videoHeight = 0;
    AVCaptureDevice *newDevice = nil;
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo] && 
            ((device.position == AVCaptureDevicePositionBack) || 
             (device.position == AVCaptureDevicePositionFront))) {
                newDevice = device;
                break;
            }
    }
    if (newDevice == nil) {
        NSLog(@"NO DEVICE FOUND!");
        return;
    }
    self.device = newDevice;
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.input];
    //NSLog(@"session preset :%@",self.captureSession.sessionPreset);
    NSError *error;
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    if (self.input) {
        [self.captureSession addInput:self.input];
    }else {
        NSLog(@"Failed to create Device input");
    }
    
    //setupOutput
    [self setupOutput];
    
    [self.captureSession commitConfiguration];
    
    AVCaptureConnection *connection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.videoMirrored = YES;
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    if (self.device.position == AVCaptureDevicePositionBack) {
        self.contentTransform = GLKMatrix4Multiply(GLKMatrix4MakeScale(-1, 1, 1), GLKMatrix4MakeRotation(-M_PI, 0,0,1));
    }else {
        self.contentTransform = GLKMatrix4MakeRotation(-M_PI, 0, 0, 1);
    }
    
    [self startCapturing];
}
- (void)startCapturing
{
    [self.videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [self.captureSession startRunning];
}

- (void)stopCapturing
{
    [self.videoDataOutput setSampleBufferDelegate:nil queue:NULL];
    [self.captureSession stopRunning];
}

-(void)setupOutput
{
    [self.captureSession removeOutput:self.videoDataOutput];
    [self.captureSession removeOutput:self.stillImageOutput];
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoDataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [self.videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [self.captureSession addOutput:self.videoDataOutput];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    self.stillImageOutput.outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    [self.captureSession addOutput:self.stillImageOutput];
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // Compensate for padding. A small black line will be visible on the right. Also adjust the texture coordinate transform to fix this.
    size_t width = CVPixelBufferGetBytesPerRow(imageBuffer)/4;
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    if (width != self.videoWidth || height != self.videoHeight) {
        self.videoWidth = width;
        self.videoHeight = height;
        //self.contentSize = CGSizeMake(width, height);
        float ratio = (float)CVPixelBufferGetWidth(imageBuffer)/width;
        NSLog(@"ratio :%f",ratio);
        self.texcoordTransform = (GLKMatrix2){1, 0, 0, 1}; // Apply a horizontal stretch to hide the row padding
        [self _setTextureData:baseAddress width:self.videoWidth height:self.videoHeight];
    }
    else {
        [self _updateTextureWithData:baseAddress];
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
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
