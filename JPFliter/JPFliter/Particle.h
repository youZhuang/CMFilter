//
//  Particle.h
//  JPFliter
//
//  Created by yiyang yuan on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Particle : NSObject

@property (nonatomic,assign) GLuint texture;
@property (nonatomic,assign) float position_x;
@property (nonatomic,assign) float position_y;
@property (nonatomic,assign) float size;
@property (nonatomic,assign) float speed;

@end
