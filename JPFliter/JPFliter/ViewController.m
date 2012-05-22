//
//  ViewController.m
//  JPFliter
//
//  Created by yiyang yuan on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "JPFilteredView.h"

NSString *filterNames[13] = {@"正常",@"允吸效果",@"马赛克",@"水彩",@"灰度",@"横向模糊",@"纵向模糊",@"横纵向模糊",@"灰度+横纵向模糊",@"Mosaic",@"CSEEmBoss",@"混合贴图",@"Alpha测试"};


@interface ViewController ()
{
    int filterIndex;
    
    UILabel *filterLabel;
}
@property (nonatomic,retain) NSArray *paths;
-(void)loadFilers;
@end

@implementation ViewController
@synthesize cameraView = _cameraView;
@synthesize cameraTargetView = _cameraTargetView;
@synthesize paths = _paths;
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    CGRect rect = [[UIScreen mainScreen] bounds];
    _cameraView = [[[JPFilteredCameraView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, rect.size.height)] autorelease];
    
    [self loadFilers];
    
    filterIndex = 0;
    NSArray *defaultPath = [_paths objectAtIndex:filterIndex];
    
    NSError *error ;
    if (![_cameraView setFilterFragmentShadersFromFiles:defaultPath error:&error]) {
        NSLog(@"setfilter framement shaders error :%@",error);
    }
    
    [self.view addSubview:_cameraView];
    
    [_cameraView startCapturing];
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewTapAction:)];
    [self.cameraView addGestureRecognizer:tgr];
    
    _cameraTargetView = [[CameraTargetView alloc] initWithFrame:CGRectMake(0, 0, 65, 65)];
    [self.view addSubview:_cameraTargetView];
    [_cameraTargetView release];
    [self.cameraTargetView hideAnimated:NO];
    
    UIButton *changeFilterBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [changeFilterBtn setTitle:@"next effect" forState:UIControlStateNormal];
    changeFilterBtn.frame = CGRectMake(0, rect.size.height - 40 - 20, 100, 40);
    [changeFilterBtn addTarget:self action:@selector(changeFilterButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:changeFilterBtn];
    
    UIButton *captureBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [captureBtn setTitle:@"take a picture" forState:UIControlStateNormal];
    captureBtn.frame = CGRectMake(320-120, rect.size.height - 40 - 20, 100, 40);
    [captureBtn addTarget:self action:@selector(takeAPictureButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:captureBtn];
    
    UIButton *switchCameraBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [switchCameraBtn setTitle:@"切换摄像头" forState:UIControlStateNormal];
    switchCameraBtn.frame = CGRectMake(320-120, 10, 100, 40);
    [switchCameraBtn addTarget:self action:@selector(cameraPostionChange:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:switchCameraBtn];
    
    
    filterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    filterLabel.textColor = [UIColor whiteColor];
    filterLabel.backgroundColor = [UIColor clearColor];
    filterLabel.textAlignment = UITextAlignmentLeft;
    filterLabel.text = filterNames[filterIndex];
    [self.view addSubview:filterLabel];
    [filterLabel release];
}

-(void)dealloc
{
    [super dealloc];
}

-(void)loadFilers
{
    NSString *luminancePath = [[NSBundle mainBundle] pathForResource:@"LuminanceFragmentShader" ofType:@"glsl"];
    NSString *hBlurPath = [[NSBundle mainBundle] pathForResource:@"HGaussianBlur" ofType:@"glsl"];
    NSString *vBlurPath = [[NSBundle mainBundle] pathForResource:@"VGaussianBlur" ofType:@"glsl"];
    NSString *defaultPath = [[NSBundle mainBundle] pathForResource:@"DefaultFragmentShader" ofType:@"glsl"];
    NSString *discretizePath = [[NSBundle mainBundle] pathForResource:@"DiscretizeShader" ofType:@"glsl"];
    NSString *pixelatePath = [[NSBundle mainBundle] pathForResource:@"PixelateShader" ofType:@"glsl"];
    NSString *suckPath = [[NSBundle mainBundle] pathForResource:@"SuckShader" ofType:@"glsl"];
    NSString *mosaicPath = [[NSBundle mainBundle] pathForResource:@"MosacShader" ofType:@"glsl"];
    NSString *cseembossPath = [[NSBundle mainBundle] pathForResource:@"CSEEmBossShader" ofType:@"glsl"];
    //NSString *pencelPath = [[NSBundle mainBundle] pathForResource:@"PancelShader" ofType:@"glsl"];
    NSString *multitexPath = [[NSBundle mainBundle] pathForResource:@"MultiTextureShader" ofType:@"glsl"];
    NSString *alphaTestPath = [[NSBundle mainBundle] pathForResource:@"AlphaTestShader" ofType:@"glsl"];
    // Setup a combination of these filters
    _paths = [[NSArray alloc] initWithObjects:
             [[NSArray alloc] initWithObjects:defaultPath, nil],
             [[NSArray alloc] initWithObjects:suckPath, nil],
             [[NSArray alloc] initWithObjects:pixelatePath, nil],
             [[NSArray alloc] initWithObjects:discretizePath, nil],
             [[NSArray alloc] initWithObjects:luminancePath, nil], 
             [[NSArray alloc] initWithObjects:hBlurPath, nil],
             [[NSArray alloc] initWithObjects:vBlurPath, nil],
             [[NSArray alloc] initWithObjects:hBlurPath, vBlurPath, nil],
             [[NSArray alloc] initWithObjects:luminancePath, hBlurPath, vBlurPath, nil], 
             [[NSArray alloc] initWithObjects:mosaicPath, nil],
             [[NSArray alloc] initWithObjects:cseembossPath, nil],
             [[NSArray alloc] initWithObjects:multitexPath, nil],
             [[NSArray alloc] initWithObjects:alphaTestPath, nil],nil];
}

#pragma mark - Button Actions

- (void)takeAPictureButtonTouchUpInside:(id)sender 
{
    if (self.cameraView.isMultiTexture) {
        UIImage *image = [self.cameraView takeScreenshot];
        NSLog(@"image size :%@",NSStringFromCGSize(image.size));
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [self.view addSubview:imageView];
        imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, imageView.frame.size.width, 40)];
        label.textAlignment = UITextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:18];
        label.text = @"This is an UIImageView";
        [imageView addSubview:label];
        
        imageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        imageView.alpha = 0.5;
        
        [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
            imageView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            imageView.alpha = 1;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:4 options:0 animations:^{
                imageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                imageView.alpha = 0;
            } completion:^(BOOL finished) {
                [imageView removeFromSuperview];
                [_cameraView SafeReleasePixels];
            }];
        }];
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
        return;
    }
    [self.cameraView takeAPhotoWithCompletion:^(UIImage *image) {
        
        NSLog(@"image size :%@",NSStringFromCGSize(image.size));
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [self.view addSubview:imageView];
        imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, imageView.frame.size.width, 40)];
        label.textAlignment = UITextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:18];
        label.text = @"This is an UIImageView";
        [imageView addSubview:label];
        
        imageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        imageView.alpha = 0.5;
        
        [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
            imageView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            imageView.alpha = 1;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:4 options:0 animations:^{
                imageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                imageView.alpha = 0;
            } completion:^(BOOL finished) {
                [imageView removeFromSuperview];
                [_cameraView SafeReleasePixels];
            }];
        }];
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
    
    }];
}

- (void)changeFilterButtonTouchUpInside:(id)sender
{
    filterIndex += 1;
    if (filterIndex > _paths.count - 1) {
        filterIndex = 0;
    }
    NSArray *files = [_paths objectAtIndex:filterIndex];
    
    if (files == nil) {
        return;
    }
    if (filterIndex ==  11) {
        self.cameraView.isMultiTexture = YES;
    }else {
        self.cameraView.isMultiTexture = NO;
    }
    NSError *error = nil;
    if (![self.cameraView setFilterFragmentShadersFromFiles:files error:&error]) {
        NSLog(@"Error setting shader: %@", [error localizedDescription]);
    }
    filterLabel.text = filterNames[filterIndex];

}
- (void)cameraPostionChange:(id)sender
{
    self.cameraView.cameraPosition = self.cameraView.cameraPosition == XBCameraPositionBack? XBCameraPositionFront: XBCameraPositionBack;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Gesture recognition

- (void)cameraViewTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        CGPoint location = [tgr locationInView:self.cameraView];
        if (self.cameraView.cameraPosition == XBCameraPositionBack) {
            self.cameraView.focusPoint = location;
        }
        
        self.cameraView.exposurePoint = location;
        self.cameraTargetView.center = self.cameraView.exposurePoint;
        [self.cameraTargetView showAnimated:YES];
    }
}

#pragma mark - XBFilteredCameraViewDelegate

- (void)filteredCameraViewDidBeginAdjustingFocus:(JPFilteredCameraView *)filteredCameraView
{
    // NSLog(@"Focus point: %f, %f", self.cameraView.focusPoint.x, self.cameraView.focusPoint.y);
}

- (void)filteredCameraViewDidFinishAdjustingFocus:(JPFilteredCameraView *)filteredCameraView
{
    // NSLog(@"Focus point: %f, %f", self.cameraView.focusPoint.x, self.cameraView.focusPoint.y);
    [self.cameraTargetView hideAnimated:YES];
}

- (void)filteredCameraViewDidFinishAdjustingExposure:(JPFilteredCameraView *)filteredCameraView
{
    [self.cameraTargetView hideAnimated:YES];
}

@end
