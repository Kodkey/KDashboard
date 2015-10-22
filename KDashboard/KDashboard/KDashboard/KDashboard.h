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
-(void)dashboard:(KDashboard*)dashboard userStartedDragging:(UIView*)draggedCell;
-(void)endDraggingFromDashboard:(KDashboard*)dashboard;
-(void)dashboard:(KDashboard *)dashboard userDraggedCellInsideDashboard:(UIView *)draggedCell;
-(void)dashboard:(KDashboard *)dashboard userDraggedCellOutsideDashboard:(UIView *)draggedCell;

-(void)dashboard:(KDashboard*)dashboard userTappedOnACellAtThisIndex:(NSInteger)index;

-(void)dashboard:(KDashboard*)dashboard swapCellAtIndex:(NSInteger)sourceIndex withCellAtIndex:(NSUInteger)destinationIndex;
-(void)dashboard:(KDashboard*)dashboard insertCellFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex;
-(void)dashboard:(KDashboard*)dashboard deleteCellAtIndex:(NSInteger)index;

-(void)dashboard:(KDashboard *)dashboard canCreateGroupAtIndex:(NSInteger)index withSourceIndex:(NSInteger)sourceIndex;
-(void)dismissGroupCreationPossibilityFromDashboard:(KDashboard*)dashboard;
-(void)dashboard:(KDashboard*)dashboard addGroupAtIndex:(NSInteger)index withCellAtIndex:(NSInteger)sourceIndex;
@end



@interface KDashboard : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate, CollectionViewEmbedderViewControllerDataSource, CollectionViewEmbedderViewControllerDelegate>

@property (nonatomic, assign) id<KDashboardDataSource> dataSource;
@property (nonatomic, assign) id<KDashboardDelegate> delegate;

-(id) initWithFrame:(CGRect)frame andDataSource:(id<KDashboardDataSource>)dataSource andDelegate:(id<KDashboardDelegate>)delegate andCellClass:(Class)cellClass andReuseIdentifier:(NSString*)identifier andAssociateToThisViewController:(UIViewController*)viewController;

-(void) associateADeleteZone:(UIView*)deleteZone;
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

// OPTIONS //
@property (nonatomic) BOOL showPageControlWhenOnlyOnePage;
@property (nonatomic) BOOL showPageControl;

@property (nonatomic) BOOL enableDragAndDrop;
@property (nonatomic) BOOL enableSwappingAction;
@property (nonatomic) BOOL enableInsertingAction;
@property (nonatomic) BOOL enableGroupCreation;

@property (nonatomic) CGFloat minimumPressDurationToStartDragging;
@property (nonatomic) CGFloat slidingPageWhileDraggingWaitingDuration;
@property (nonatomic) CGFloat minimumWaitingDurationToCreateAGroup;

//*********//

-(UICollectionViewCell*)cellAtDashboardIndex:(NSInteger)index;

@end
