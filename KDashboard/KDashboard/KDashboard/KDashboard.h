//
//  KDashboard.h
//  KDashboard
//
//  Created by COURELJordan on 13/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KDashboardDataSource <NSObject>
@required
-(NSInteger)numberOfRowsPerPage;
-(NSInteger)numberOfColumnsPerPage;
@end

@protocol KDashboardDelegate <NSObject>
@optional

@end

@interface KDashboard : UIView <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, assign) id<KDashboardDataSource> dataSource;
@property (nonatomic, assign) id<KDashboardDelegate> delegate;

-(id) initWithFrame:(CGRect)frame;

-(void) associateADeleteZone:(UIView*)deleteZone;
-(void) registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString*)identifier;

@end
