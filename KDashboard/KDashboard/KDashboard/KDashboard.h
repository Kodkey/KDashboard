//
//  KDashboard.h
//  KDashboard
//
//  Created by KODKEY on 13/10/2015.
//  Copyright (c) 2015 KODKEY. All rights reserved.
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

-(BOOL)dashboard:(KDashboard*)dashboard swapCellAtIndex:(NSInteger)sourceIndex withCellAtIndex:(NSUInteger)destinationIndex;
-(BOOL)dashboard:(KDashboard*)dashboard insertCellFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex;
-(BOOL)dashboard:(KDashboard*)dashboard deleteCellAtIndex:(NSInteger)index;

-(void)dashboard:(KDashboard *)dashboard canCreateGroupAtIndex:(NSInteger)index withSourceIndex:(NSInteger)sourceIndex;
-(void)dismissGroupCreationPossibilityFromDashboard:(KDashboard*)dashboard;
-(void)dashboard:(KDashboard*)dashboard addGroupAtIndex:(NSInteger)index withCellAtIndex:(NSInteger)sourceIndex;

-(BOOL)dashboard:(KDashboard*)dashboard swapCellAtIndex:(NSInteger)sourceIndex withCellAtIndex:(NSUInteger)destinationIndex fromAnotherDashboard:(KDashboard*)anotherDashboard;
-(BOOL)dashboard:(KDashboard*)dashboard insertCellFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex fromAnotherDashboard:(KDashboard*)anotherDashboard;
-(void)dashboard:(KDashboard*)dashboard addGroupAtIndex:(NSInteger)index withCellAtIndex:(NSInteger)sourceIndex fromAnotherDashboard:(KDashboard*)anotherDashboard;
@end



@interface KDashboard : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate, CollectionViewEmbedderViewControllerDataSource, CollectionViewEmbedderViewControllerDelegate>

-(id) initWithFrame:(CGRect)frame andDataSource:(id<KDashboardDataSource>)dataSource andDelegate:(id<KDashboardDelegate>)delegate andCellClass:(Class)cellClass andReuseIdentifier:(NSString*)identifier andAssociateToThisViewController:(UIViewController*)viewController;
-(void) display;

-(void) associateADeleteZone:(UIView*)deleteZone;
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index;
-(UICollectionViewCell*)cellAtDashboardIndex:(NSInteger)index;
-(void) reloadData;


// USEFUL FOR DASHBOARD ITSELF ONLY //
@property (nonatomic, weak) UIViewController* viewControllerEmbedder;
@property (nonatomic, retain) UIView* draggedCell;
@property (nonatomic) BOOL movedDraggedCell;

@property (nonatomic) NSInteger indexOfTheLastDraggedCellSource;
@property (nonatomic) BOOL insideDashboard;

@property (nonatomic, weak) KDashboard* sourceDashboard;

-(void) handlePress:(UILongPressGestureRecognizer*)gesture;
-(void) handlePan:(UIPanGestureRecognizer*)gesture;

@property (nonatomic) NSString* uid;
//*********//


// OPTIONS //
@property (nonatomic) BOOL bounces;

@property (nonatomic) BOOL showPageControlWhenOnlyOnePage;
@property (nonatomic) BOOL showPageControl;

@property (nonatomic) BOOL enableDragAndDrop;
@property (nonatomic) BOOL enableSwappingAction;
@property (nonatomic) BOOL enableInsertingAction;
@property (nonatomic) BOOL enableGroupCreation;

@property (nonatomic) BOOL enableSwappingActionFromAnotherDashboard;
@property (nonatomic) BOOL enableInsertingActionFromAnotherDashboard;
@property (nonatomic) BOOL enableGroupCreationFromAnotherDashboard;

@property (nonatomic) CGFloat minimumPressDurationToStartDragging;//shared by all dashboards
@property (nonatomic) CGFloat slidingPageWhileDraggingWaitingDuration;
@property (nonatomic) CGFloat minimumWaitingDurationToCreateAGroup;
//*********//


@end
