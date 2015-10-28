//
//  KDashboardGestureManagerViewController.h
//  KDashboard
//
//  Created by KODKEY on 23/10/2015.
//  Copyright (c) 2015 KODKEY. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KDashboard;
@interface KDashboardGestureManagerViewController : UIViewController <UIGestureRecognizerDelegate>

+(id) sharedManager;

-(void) registerDashboardForDragAndDrop:(KDashboard*)dashboard;
-(void) unregisterDashboardForDragAndDrop:(KDashboard*)dashboard;
-(void) dissociateADashboard:(KDashboard*)dashboard;

-(BOOL)knowsThisDashboard:(KDashboard*)dashboard;
-(BOOL)isStillThereAVisibleDashboard;

-(void) setMinimumPressDurationToStartDragging:(CGFloat)minimumPressDuration;

@end
