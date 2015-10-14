//
//  KDashboard.m
//  KDashboard
//
//  Created by COURELJordan on 13/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import "KDashboard.h"

#define IS_IOS7 ([[[UIDevice currentDevice] systemVersion] floatValue] == 7.0)

#define PAGE_VIEW_CONTROLLER_HEIGHT_PERCENTAGE 90
#define ASIDE_SLIDING_DETECTION_ZONE_WIDTH_PERCENTAGE 7

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
@property (nonatomic) NSInteger pageIndex;

@end

@implementation KDashboard

#pragma mark - initialisation
-(id) initWithFrame:(CGRect)frame andDataSource:(id<KDashboardDataSource>)dataSource andDelegate:(id<KDashboardDelegate>)delegate andCellClass:(__unsafe_unretained Class)cellClass andReuseIdentifier:(NSString *)identifier{
    if(self = [super init]){
        [self setDefaultOptions];
        
        _dataSource = dataSource;
        _delegate = delegate;
        _cellClass = cellClass;
        _identifier = identifier;
        
        [self.view setFrame:frame];
        
        [self layoutSubviews];
    }
    return self;
}

-(void) setDefaultOptions{
    _showPageControl = YES;
    _showPageControlWhenOnlyOnePage = YES;
}

-(void) layoutSubviews{
    [self removeUIElementsFromSuperview];
    
    _pageViewController = [self createPageViewControllerWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height*(_showPageControl ? (float)PAGE_VIEW_CONTROLLER_HEIGHT_PERCENTAGE/100 : 1))];
    [self loadInitialViewControllerAtIndex:0 withAnimation:NO andDirection:UIPageViewControllerNavigationDirectionForward andCompletionBlock:nil];
    
    CGFloat asideZoneWidth = self.view.frame.size.width*ASIDE_SLIDING_DETECTION_ZONE_WIDTH_PERCENTAGE/100;
    _leftSideSlidingDetectionZone = [self createAsideDetectionZoneWithFrame:CGRectMake(0, 0, asideZoneWidth, self.view.frame.size.height)];
    _rightSideSlidingDetectionZone = [self createAsideDetectionZoneWithFrame:CGRectMake(self.view.frame.size.width-asideZoneWidth, 0, asideZoneWidth, self.view.frame.size.height)];
    
    if(_showPageControl){
        _pageControl = [self createPageControlWithFrame:CGRectMake(0, CGRectGetMaxY(_pageViewController.view.frame), self.view.frame.size.width, self.view.frame.size.height-_pageViewController.view.frame.size.height)];
        [self reloadNumberOfPages];
        _pageControl.currentPage = _pageIndex;
    }
    
}

-(void) removeUIElementsFromSuperview{
    if(_pageViewController != nil){
        [_pageViewController willMoveToParentViewController:nil];
        [_pageViewController.view removeFromSuperview];
        [_pageViewController removeFromParentViewController];
    }
    if(_leftSideSlidingDetectionZone != nil)[_leftSideSlidingDetectionZone removeFromSuperview];
    if(_rightSideSlidingDetectionZone != nil)[_rightSideSlidingDetectionZone removeFromSuperview];
    if(_pageControl != nil)[_pageControl removeFromSuperview];
}

#pragma mark - creating UI elements associated to the Dashboard
-(UIPageViewController*) createPageViewControllerWithFrame:(CGRect)frame{
    UIPageViewController* aPageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    aPageViewController.view.backgroundColor = [UIColor clearColor];
    
    aPageViewController.dataSource = self;
    aPageViewController.delegate = self;
    [aPageViewController.view setFrame:frame];
    
    [self addChildViewController:aPageViewController];
    [self.view addSubview:aPageViewController.view];
    [aPageViewController didMoveToParentViewController:self];
    
    return aPageViewController;
}

-(UIView*) createAsideDetectionZoneWithFrame:(CGRect)frame{
    UIView* anAsideDetectionZone = [[UIView alloc] initWithFrame:frame];
    anAsideDetectionZone.backgroundColor = [UIColor clearColor];
    [self.view addSubview:anAsideDetectionZone];
    
    return anAsideDetectionZone;
}

-(UIPageControl*) createPageControlWithFrame:(CGRect)frame{
    UIPageControl* aPageControl = [[UIPageControl alloc] initWithFrame:frame];
    aPageControl.backgroundColor = [UIColor redColor];
    aPageControl.enabled = NO;
    
    [self.view addSubview:aPageControl];
    
    return aPageControl;
}

#pragma mark - managing UI elements
-(void) loadInitialViewControllerAtIndex:(NSInteger)index withAnimation:(BOOL)animated andDirection:(NSInteger)direction andCompletionBlock:(void(^)(BOOL))completionBlock{
    CollectionViewEmbedderViewController* initialViewController = [self viewControllerAtIndex:index];
    _currentCollectionViewEmbedder = initialViewController;

    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];

    if(IS_IOS7){//bug fix in iOS7
        __block KDashboard *blocksafeSelf = self;
        [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished){
            if(finished)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [blocksafeSelf.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:completionBlock];// bug fix for uipageview controller
                });
            }
        }];
    }else{
        [_pageViewController setViewControllers:viewControllers direction:direction animated:animated completion:completionBlock];
    }
    
    [self reloadNumberOfPages];
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers NS_AVAILABLE_IOS(6_0){
    if(pageViewController == _pageViewController){
        for(UIViewController* pendingViewController in pendingViewControllers){
            CollectionViewEmbedderViewController* embedder = (CollectionViewEmbedderViewController*)pendingViewController;
            [embedder.collectionView reloadData];
        }
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed{
    _currentCollectionViewEmbedder = [pageViewController.viewControllers lastObject];
    [self setPageIndex:_currentCollectionViewEmbedder.pageIndex];
}

- (CollectionViewEmbedderViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(CollectionViewEmbedderViewController*)viewController {
    
    NSUInteger index = [(CollectionViewEmbedderViewController*)viewController pageIndex];
    if (index == 0) {
        return nil;
    }
    index--;
    
    return [self viewControllerAtIndex:index];
}

- (CollectionViewEmbedderViewController*)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(CollectionViewEmbedderViewController*)viewController {
    
    NSUInteger index = [(CollectionViewEmbedderViewController*)viewController pageIndex];
    index++;
    if (index >= [self pageCount]) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
}

- (CollectionViewEmbedderViewController*)viewControllerAtIndex:(NSUInteger)index{    
    CollectionViewEmbedderViewController* collectionViewEmbedder = [[CollectionViewEmbedderViewController alloc] initWithFrame:CGRectMake(0, 0, _pageViewController.view.frame.size.width, _pageViewController.view.frame.size.height) andDataSource:self andDelegate:self andCellClass:_cellClass andReuseIdentifier:_identifier];
    collectionViewEmbedder.pageIndex = index;
    
    return collectionViewEmbedder;
}

-(void) pageViewController:(UIPageViewController*)pageViewController switchToThisViewController:(CollectionViewEmbedderViewController*)targetedViewController withDirection:(NSInteger)direction{
    __weak UIPageViewController* pvcw = pageViewController;
    [_pageViewController setViewControllers:@[targetedViewController]
                                  direction:direction
                                   animated:YES completion:^(BOOL finished) {
                                       UIPageViewController* pvcs = pvcw;
                                       if (!pvcs) return;
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [pvcs setViewControllers:@[targetedViewController]
                                                          direction:direction
                                                           animated:NO completion:^(BOOL finished){
                                                           }];
                                       });
                                   }];
    _currentCollectionViewEmbedder = [pageViewController.viewControllers lastObject];
    [self setPageIndex:_currentCollectionViewEmbedder.pageIndex];
    
}

-(void) setPageIndex:(NSInteger)pageIndex{
    _pageIndex = pageIndex;
    _pageControl.currentPage = pageIndex;
}

-(void) reloadNumberOfPages{
    _pageControl.numberOfPages = [self pageCount];
    if(!_showPageControlWhenOnlyOnePage){
        if(_pageControl.numberOfPages <= 1){
            _pageControl.numberOfPages = 0;
        }
    }
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index{
    return [_currentCollectionViewEmbedder dequeueReusableCellWithIdentifier:identifier forIndex:index];
}

-(NSUInteger) pageCount{
    return ceil((float)[_dataSource cellCountInDashboard:self]/(float)([_dataSource columnCountPerPageInDashboard:self]*[_dataSource rowCountPerPageInDashboard:self]));
}

#pragma mark - CollectionViewEmbedderViewController dataSource methods
-(NSUInteger)maxRowCount{
    return [_dataSource rowCountPerPageInDashboard:self];
}

-(NSUInteger)maxColumnCount{
    return [_dataSource columnCountPerPageInDashboard:self];
}

-(NSInteger)numberOfItemsInThisCollectionViewEmbedderViewController:(CollectionViewEmbedderViewController*)collectionViewEmbedderViewController{
    NSInteger numberOfItems;
    
    if(collectionViewEmbedderViewController.pageIndex == [self pageCount]-1){
        numberOfItems = [_dataSource cellCountInDashboard:self]%([_dataSource rowCountPerPageInDashboard:self]*[_dataSource columnCountPerPageInDashboard:self]);
    }else{
        numberOfItems = [_dataSource rowCountPerPageInDashboard:self]*[_dataSource columnCountPerPageInDashboard:self];
    }
    
    return numberOfItems;
}

-(UICollectionViewCell *)collectionViewEmbedderViewController:(CollectionViewEmbedderViewController*)collectionViewEmbedder cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    _currentCollectionViewEmbedder = collectionViewEmbedder;
    return [_dataSource dashboard:self cellForItemAtIndex:indexPath.row+collectionViewEmbedder.pageIndex*([_dataSource rowCountPerPageInDashboard:self]*[_dataSource columnCountPerPageInDashboard:self])];
}

#pragma mark - associateADeleteZone: - associate a view from the superview where a dragged cell can be deleted
-(void) associateADeleteZone:(UIView*)deleteZone{
    _deleteZone = deleteZone;
}

#pragma mark - options methods
-(void) setShowPageControlWhenOnlyOnePage:(BOOL)showPageControlWhenOnlyOnePage{
    _showPageControlWhenOnlyOnePage = showPageControlWhenOnlyOnePage;
    [self reloadNumberOfPages];
}

-(void) setShowPageControl:(BOOL)showPageControl{
    _showPageControl = showPageControl;
    [self layoutSubviews];
}

#pragma mark - registerClass:forCellWithReuseIdentifier: - used for the currentCollectionViewEmbedder
-(void) registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString*)identifier{
    _cellClass = cellClass;
    _identifier = identifier;
}

@end
