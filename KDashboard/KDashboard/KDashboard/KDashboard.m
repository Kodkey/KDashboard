//
//  KDashboard.m
//  KDashboard
//
//  Created by COURELJordan on 13/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import "KDashboard.h"

#import "CollectionViewEmbedderViewController.h"

#define PAGE_VIEW_CONTROLLER_HEIGHT_PERCENTAGE 90

@interface KDashboard ()

@property (nonatomic, weak) id superviewEmbedder;
@property (nonatomic, weak) UIView* deleteZone;
@property (nonatomic, retain) UIView* draggedCell;

@property (nonatomic, weak) UIPageViewController* pageViewController;
@property (nonatomic, weak) CollectionViewEmbedderViewController* currentCollectionViewEmbedder;
@property (nonatomic, retain) Class cellClass;
@property (nonatomic, retain) NSString* identifier;
@property (nonatomic, weak) UIView* leftSideSlidingDetectionZone;
@property (nonatomic, weak) UIView* rightSideSlidingDetectionZone;
@property (nonatomic, weak) UIPageControl* pageControl;

@end

@implementation KDashboard

#pragma mark - initialisation
-(id) initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        
    }
    return self;
}

-(void) layoutSubviews{
    [super layoutSubviews];
    
    _pageViewController = [self createPageViewControllerWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height*PAGE_VIEW_CONTROLLER_HEIGHT_PERCENTAGE/100)];
    _pageControl = [self createPageControlWithFrame:CGRectMake(0, CGRectGetMaxY(_pageViewController.view.frame), self.frame.size.width, self.frame.size.height-CGRectGetMaxY(_pageViewController.view.frame))];
}

#pragma mark - create UI elements associated to the Dashboard
-(UIPageViewController*) createPageViewControllerWithFrame:(CGRect)frame{
    UIPageViewController* aPageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    aPageViewController.view.backgroundColor = [UIColor clearColor];
    
    aPageViewController.dataSource = self;
    aPageViewController.delegate = self;
    [_pageViewController.view setFrame:frame];
    
    [self loadInitialViewControllerAtIndex:0 withAnimation:NO andDirection:UIPageViewControllerNavigationDirectionForward andCompletionBlock:nil];
    
    [self addSubview:aPageViewController.view];
    
    _slidingToPreviousPageDetectionZone = [SLUIFabric createViewWithBackgroundColor:nil andFrame:CGRectMake(0, [SLUIConfig getDashboardPositionY], [SLUIConfig slidingToNewPageDetectionZoneMarginX], [SLUIConfig getDashboardHeight]) andAssociateItToThisParentView:self.view];
    _slidingToNextPageDetectionZone = [SLUIFabric createViewWithBackgroundColor:nil andFrame:CGRectMake([SLUIConfig getDashboardWidth]-[SLUIConfig slidingToNewPageDetectionZoneMarginX], [SLUIConfig getDashboardPositionY], [SLUIConfig slidingToNewPageDetectionZoneMarginX], [SLUIConfig getDashboardHeight]) andAssociateItToThisParentView:self.view];
    
    [self createPageControlWithFrame:CGRectMake(0, _pageViewController.view.frame.origin.y+_pageViewController.view.frame.size.height, [SLUIConfig getBarWidth], [SLUIConfig getPageControlHeight])];
    
    return aPageViewController;
}

-(UIView*) createAsideDetectionZoneWithFrame:(CGRect)frame{
    UIView* anAsideDetectionZone = [[UIView alloc] initWithFrame:frame];
    anAsideDetectionZone.backgroundColor = [UIColor clearColor];
    [self addSubview:anAsideDetectionZone];
    
    return anAsideDetectionZone;
}

-(UIPageControl*) createPageControlWithFrame:(CGRect)frame{
    UIPageControl* pageControl;
    
    return pageControl;
}

#pragma mark - associateADeleteZone: - associate a view from the superview where a dragged cell can be deleted
-(void) associateADeleteZone:(UIView*)deleteZone{
    _deleteZone = deleteZone;
}

#pragma mark - registerClass:forCellWithReuseIdentifier: - used for the currentCollectionViewEmbedder
-(void) registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString*)identifier{
    _cellClass = cellClass;
    _identifier = identifier;
}

@end
