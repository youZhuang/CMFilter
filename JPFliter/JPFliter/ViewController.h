//
//  ViewController.h
//  JPFliter
//
//  Created by yiyang yuan on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "JPFilteredCameraView.h"
#import "XBFilteredCameraView.h"
#import "CameraTargetView.h"

@interface ViewController : UIViewController<XBFilteredCameraViewDelegate>

@property (nonatomic,retain) XBFilteredCameraView *cameraView;
@property (nonatomic,retain) CameraTargetView *cameraTargetView;

- (void)takeAPictureButtonTouchUpInside:(id)sender;
- (void)changeFilterButtonTouchUpInside:(id)sender;
- (void)cameraButtonTouchUpInside:(id)sender;

@end
