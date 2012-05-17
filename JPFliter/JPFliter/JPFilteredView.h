//
//  JPFilteredView.h
//  JPFliter
//
//  Created by yiyang yuan on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface JPFilteredView : UIView

@property (nonatomic,assign) GLKMatrix4 contentTransform;
@property (nonatomic,assign) GLKMatrix2 texcoordTransform;

-(void)render;

-(BOOL)setFilterFragmentShaderFromFile:(NSString*)path error:(NSError *__autoreleasing *)error;

@end
