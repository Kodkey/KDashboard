//
//  DotView.m
//  KDashboard
//
//  Created by COURELJordan on 21/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import "DotView.h"

@implementation DotView

-(id) initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = frame.size.width/2;
    }
    return self;
}

@end
