//
//  KDashboard.h
//  KDashboard
//
//  Created by COURELJordan on 13/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CollectionViewEmbedderViewController.h"

@class KDashboard;
@protocol KDashboardDataSource <NSObject>
@required
-(NSUInteger)rowCountPerPageInDashboard:(KDashboard*)dashboard;
-(NSUInteger)columnCountPerPageInDashboard:(KDashboard*)dashboard;
-(NSUInteger)cellCountInDashboard:(KDashboard*)dashboard;
-(UICollectionViewCell*)dashboard:(KDashboard*)dashboard cellForItemAtIndex:(NSUInteger)index;
@end

@protocol KDashboardDelegate <NSObject>
@optional
-(void)startDraggingFromDashboard:(KDashboard*)dashboard;
-(void)endDraggingFromDashboard:(KDashboard*)dashboard;

-(void)dashboard:(KDashboard*)dashboard userTappedOnACellAtThisIndex:(NSUInteger)index;

-(void)dashboard:(KDashboard*)dashboard swapCellAtIndex:(NSUInteger)sourceIndex withCellAtIndex:(NSUInteger)destinationIndex;
-(void)dashboard:(KDashboard*)dashboard insertCellAtIndex:(NSUInteger)index;
-(void)dashboard:(KDashboard*)dashboard deleteCellAtIndex:(NSUInteger)index;

-(void)dashboard:(KDashboard*)dashboard createGroupAtIndex:(NSUInteger)index withCellAtIndex:(NSUInteger)sourceCell andCellAtIndex:(NSUInteger)destinationIndex;
-(void)dashboard:(KDashboard*)dashboard addCellAtIndex:(NSUInteger)sourceIndex toGroupAtIndex:(NSUInteger)destinationIndex;
@end



@interface KDashboard : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, CollectionViewEmbedderViewControllerDataSource, CollectionViewEmbedderViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, assign) id<KDashboardDataSource> dataSource;
@property (nonatomic, assign) id<KDashboardDelegate> delegate;

-(id) initWithFrame:(CGRect)frame andDataSource:(id<KDashboardDataSource>)dataSource andDelegate:(id<KDashboardDelegate>)delegate andCellClass:(Class)cellClass andReuseIdentifier:(NSString*)identifier andAssociateToThisViewController:(UIViewController*)viewController;

-(void) associateADeleteZone:(UIView*)deleteZone;
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

// OPTIONS //
@property (nonatomic) BOOL showPageControlWhenOnlyOnePage;
@property (nonatomic) BOOL showPageControl;

@property (nonatomic) BOOL enableDragAndDrop;
@property (nonatomic) CGFloat minimumPressDurationToStartDragging;

@property (nonatomic) CGFloat slidingPageWhileDraggingWaitingDuration;
//*********//

@end
