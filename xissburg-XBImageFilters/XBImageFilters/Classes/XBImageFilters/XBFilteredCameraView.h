//
//  XBFilteredCameraView.h
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "XBFilteredView.h"

typedef enum {
    XBCameraPositionBack = 1,
    XBCameraPositionFront = 2
} XBCameraPosition;

typedef enum {
    XBFlashModeOff = 0,
    XBFlashModeOn = 1,
    XBFlashModeAuto = 2
} XBFlashMode;

typedef enum {
    XBTorchModeOff = 0,
    XBTorchModeOn = 1,
    XBTorchModeAuto = 2
} XBTorchMode;

typedef enum {
    XBPhotoOrientationAuto = 0, // Determines photo orientation from [UIDevice currentDevice]'s orientation
    XBPhotoOrientationPortrait = 1,
    XBPhotoOrientationPortraitUpsideDown = 2,
    XBPhotoOrientationLandscapeLeft = 3,
    XBPhotoOrientationLandscapeRight = 4,
} XBPhotoOrientation;

extern NSString *const XBCaptureQualityPhoto;
extern NSString *const XBCaptureQualityHigh;
extern NSString *const XBCaptureQualityMedium;
extern NSString *const XBCaptureQualityLow;
extern NSString *const XBCaptureQuality1280x720;
extern NSString *const XBCaptureQualityiFrame1280x720;
extern NSString *const XBCaptureQualityiFrame960x540;
extern NSString *const XBCaptureQuality640x480;
extern NSString *const XBCaptureQuality352x288;

@class XBFilteredCameraView;

@protocol XBFilteredCameraViewDelegate <NSObject>

@optional
- (void)filteredCameraViewDidBeginAdjustingFocus:(XBFilteredCameraView *)filteredCameraView;
- (void)filteredCameraViewDidFinishAdjustingFocus:(XBFilteredCameraView *)filteredCameraView;
- (void)filteredCameraViewDidBeginAdjustingExposure:(XBFilteredCameraView *)filteredCameraView;
- (void)filteredCameraViewDidFinishAdjustingExposure:(XBFilteredCameraView *)filteredCameraView;
- (void)filteredCameraViewDidBeginAdjustingWhiteBalance:(XBFilteredCameraView *)filteredCameraView;
- (void)filteredCameraViewDidFinishAdjustingWhiteBalance:(XBFilteredCameraView *)filteredCameraView;

@end

@interface XBFilteredCameraView : XBFilteredView <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet id<XBFilteredCameraViewDelegate> delegate;
@property (assign, nonatomic) XBCameraPosition cameraPosition;
@property (assign, nonatomic) CGPoint focusPoint; // Only supported if cameraPosition is XBCameraPositionBack
@property (assign, nonatomic) CGPoint exposurePoint;
@property (copy, nonatomic) NSString *videoCaptureQuality;
@property (copy, nonatomic) NSString *imageCaptureQuality;
@property (assign, nonatomic) XBFlashMode flashMode;
@property (assign, nonatomic) XBTorchMode torchMode;
@property (assign, nonatomic) XBPhotoOrientation photoOrientation;

/*
 * Starts/stops capturing and rendering the camera image with filters applied in realtime.
 */
- (void)startCapturing;
- (void)stopCapturing;

- (void)takeAPhotoWithCompletion:(void (^)(UIImage *image))completion;

@end
