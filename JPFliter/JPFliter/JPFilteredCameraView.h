//
//  JPFilteredCameraView.h
//  JPFliter
//
//  Created by yiyang yuan on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "JPFilteredView.h"

@interface JPFilteredCameraView : JPFilteredView <AVCaptureVideoDataOutputSampleBufferDelegate>

@end
