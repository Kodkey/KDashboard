//
//  GroupView.h
//  KDashboard
//
//  Created by KODKEY on 21/10/2015.
//  Copyright (c) 2015 KODKEY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GroupView : UIView

-(id) initWithFrame:(CGRect)frame;
-(void) setDotCount:(NSInteger)dotCount;
-(void) setRowDotCount:(NSInteger)rowDotCount andColumnDotCount:(NSInteger)columntDotCount;

@end
