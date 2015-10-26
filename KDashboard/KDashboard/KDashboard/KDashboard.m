//
//  KDashboard.m
//  KDashboard
//
//  Created by KODKEY on 13/10/2015.
//  Copyright (c) 2015 KODKEY. All rights reserved.
//

#import "KDashboard.h"
#import "KDashboardGestureManagerViewController.h"

#define IS_IOS7 ([[[UIDevice currentDevice] systemVersion] floatValue] == 7.0)

#define PAGE_VIEW_CONTROLLER_HEIGHT_PERCENTAGE 95.0
#define ASIDE_SLIDING_DETECTION_ZONE_WIDTH_PERCENTAGE 6.0
#define ASIDE_CELL_INSERTING_ZONE_WIDTH_PERCENTAGE 20.0

#define DEFAULT_MINIMUM_PRESS_DURATION_TO_START_DRAGGING 0.5
#define DEFAULT_SLIDING_PAGE_WHILE_DRAGGING_WAIT_DURATION 0.8
#define DEFAULT_MINIUM_WAITING_TO_CREATE_A_GROUP 0.8
#define DISMISS_GROUP_CREATION_SENSIBILITY 15.0

#define CANCEL_DRAGGING_ANIMATION_DURATION 0.35
#define DELETE_CELL_DISAPPEAR_ANIMATION_DURATION 0.2

#define DEFAULT_MAX_COLUMN_ROW_COUNT 3

@interface KDashboard ()

@property (nonatomic, weak) UIView* deleteZone;
@property (nonatomic, retain) UIView* bufferMovingCell;

@property (nonatomic, assign) id<KDashboardDataSource> dataSource;
@property (nonatomic, assign) id<KDashboardDelegate> delegate;

@property (nonatomic, weak) UIPageViewController* pageViewController;
@property (nonatomic, weak) UIScrollView* theScrollView;
@property (nonatomic, weak) CollectionViewEmbedderViewController* currentCollectionViewEmbedder;
@property (nonatomic, weak) CollectionViewEmbedderViewController* lastWorkingOnCollectionViewEmbedder;
@property (nonatomic, retain) Class cellClass;
@property (nonatomic, retain) NSString* identifier;
@property (nonatomic, weak) UIPageControl* pageControl;
@property (nonatomic) NSInteger pageIndex;

@property (nonatomic) NSUInteger onePageElementCount;

@property (nonatomic) CGPoint memorizedDraggedCellSourceCenter;

@property (nonatomic) CGFloat oneElementWidth;
@property (nonatomic) CGFloat oneElementHeight;
@property (nonatomic) CGPoint calculatedFirstElementCenter;
@property (nonatomic) CGPoint calculatedLastElementCenter;

@property (nonatomic, weak) UIView* leftSideSlidingDetectionZone;
@property (nonatomic, weak) UIView* rightSideSlidingDetectionZone;
@property (nonatomic, retain) NSTimer* slidingWhileDraggingTimer;

@property (nonatomic) CFAbsoluteTime lastTimeDragChangedState;
@property (nonatomic) CGPoint lastTouchPoint;
@property (nonatomic) BOOL canCreateGroup;
@property (nonatomic, retain) NSTimer* canCreateGroupTimer;
@property (nonatomic) NSInteger lastIndexWhereBeingAbleToCreateAGroup;

@end

@implementation KDashboard

/******************/
/* INITIALISATION */
/******************/
-(id) initWithFrame:(CGRect)frame andDataSource:(id<KDashboardDataSource>)dataSource andDelegate:(id<KDashboardDelegate>)delegate andCellClass:(__unsafe_unretained Class)cellClass andReuseIdentifier:(NSString *)identifier andAssociateToThisViewController:(UIViewController *)viewController{
    if(self = [super init]){
        [self setDefaultOptions];
        
        _dataSource = dataSource;
        _delegate = delegate;
        _cellClass = cellClass;
        _identifier = identifier;
        _viewControllerEmbedder = viewController;
        
        [self.view setFrame:frame];
    }
    return self;
}

-(void) display{
    _onePageElementCount = [_dataSource rowCountPerPageInDashboard:self]*[_dataSource columnCountPerPageInDashboard:self];
    if(_onePageElementCount == 0){
        _onePageElementCount = [_dataSource cellCountInDashboard:self];
    }
    
    [self layoutSubviews];
    if(_enableDragAndDrop)[self setUpGestures];
    
    NSInteger maxColumnCount, maxRowCount;
    if([_dataSource rowCountPerPageInDashboard:self] == 0 && [_dataSource columnCountPerPageInDashboard:self] == 0){
        maxColumnCount = DEFAULT_MAX_COLUMN_ROW_COUNT;
        maxRowCount = DEFAULT_MAX_COLUMN_ROW_COUNT;
    }else{
        maxColumnCount = [_dataSource columnCountPerPageInDashboard:self] == 0 ? [_dataSource rowCountPerPageInDashboard:self] : [_dataSource columnCountPerPageInDashboard:self];
        maxRowCount = [_dataSource rowCountPerPageInDashboard:self] == 0 ? [_dataSource columnCountPerPageInDashboard:self] : [_dataSource rowCountPerPageInDashboard:self];
    }
    
    _oneElementHeight = _pageViewController.view.frame.size.height/maxRowCount;
    _oneElementWidth = _pageViewController.view.frame.size.width/maxColumnCount;
    _calculatedFirstElementCenter = CGPointMake(_oneElementWidth/2,_oneElementHeight/2);
    _calculatedLastElementCenter = CGPointMake(_pageViewController.view.frame.size.width-_oneElementWidth/2,_pageViewController.view.frame.size.height-_oneElementHeight/2);
}

-(void) setDefaultOptions{
    _indexOfTheLastDraggedCellSource = -1;
    _movedDraggedCell = NO;
    
    _showPageControl = YES;
    _showPageControlWhenOnlyOnePage = YES;
    _enableDragAndDrop = YES;
    _enableSwappingAction = YES;
    _enableInsertingAction = YES;
    _enableGroupCreation = YES;
    
    _enableSwappingActionFromAnotherDashboard = YES;
    _enableInsertingActionFromAnotherDashboard = YES;
    _enableGroupCreationFromAnotherDashboard = YES;
    
    _slidingPageWhileDraggingWaitingDuration = DEFAULT_SLIDING_PAGE_WHILE_DRAGGING_WAIT_DURATION;
    _minimumWaitingDurationToCreateAGroup = DEFAULT_MINIUM_WAITING_TO_CREATE_A_GROUP;
}

-(void) layoutSubviews{
    [self removeUIElementsFromSuperview];
    
    _pageViewController = [self createPageViewControllerWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height*(_showPageControl ? (float)PAGE_VIEW_CONTROLLER_HEIGHT_PERCENTAGE/100 : 1))];
    [self loadInitialViewControllerAtIndex:0 withAnimation:NO andDirection:UIPageViewControllerNavigationDirectionForward andCompletionBlock:nil];
    
    [self setBounces:_bounces];
    
    CGFloat asideZoneWidth = self.view.frame.size.width*ASIDE_SLIDING_DETECTION_ZONE_WIDTH_PERCENTAGE/100;
    _leftSideSlidingDetectionZone = [self createAsideDetectionZoneWithFrame:CGRectMake(0, 0, asideZoneWidth, self.view.frame.size.height)];
    _rightSideSlidingDetectionZone = [self createAsideDetectionZoneWithFrame:CGRectMake(self.view.frame.size.width-asideZoneWidth, 0, asideZoneWidth, self.view.frame.size.height)];
    
    if(_showPageControl){
        _pageControl = [self createPageControlWithFrame:CGRectMake(0, CGRectGetMaxY(_pageViewController.view.frame), self.view.frame.size.width, self.view.frame.size.height-_pageViewController.view.frame.size.height)];
        [self reloadNumberOfPages];
        _pageControl.currentPage = _pageIndex;
    }
    
    [_viewControllerEmbedder addChildViewController:self];
    [_viewControllerEmbedder.view addSubview:self.view];
    [self didMoveToParentViewController:_viewControllerEmbedder];
    
    if(_enableDragAndDrop)[[KDashboardGestureManagerViewController sharedManager] registerDashboardForDragAndDrop:self];
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
    
    [[KDashboardGestureManagerViewController sharedManager] unregisterDashboardForDragAndDrop:self];
}

-(void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [[KDashboardGestureManagerViewController sharedManager] unregisterDashboardForDragAndDrop:self];
}

/************************/
/* UI ELEMENTS CREATION */
/************************/
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
    aPageControl.backgroundColor = [UIColor clearColor];
    aPageControl.enabled = NO;
    
    [self.view addSubview:aPageControl];
    
    return aPageControl;
}

/************************/
/* MANAGING UI ELEMENTS */
/************************/
-(void) loadInitialViewControllerAtIndex:(NSInteger)index withAnimation:(BOOL)animated andDirection:(UIPageViewControllerNavigationDirection)direction andCompletionBlock:(void(^)(BOOL))completionBlock{
    CollectionViewEmbedderViewController* initialViewController = [self viewControllerAtIndex:index];
    _currentCollectionViewEmbedder = initialViewController;
    
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    if(IS_IOS7){//bug fix in iOS7
        __block KDashboard *blocksafeSelf = self;
        [_pageViewController setViewControllers:viewControllers direction:direction animated:YES completion:^(BOOL finished){
            if(finished)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [blocksafeSelf.pageViewController setViewControllers:viewControllers direction:direction animated:NO completion:completionBlock];// bug fix for uipageview controller
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
    if(_pageControl != nil)_pageControl.currentPage = pageIndex;
}

-(void) reloadNumberOfPages{
    if(_pageControl != nil){
        _pageControl.numberOfPages = [self pageCount];
        if(!_showPageControlWhenOnlyOnePage){
            if(_pageControl.numberOfPages <= 1){
                _pageControl.numberOfPages = 0;
            }
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_pageIndex == 0 && scrollView.contentOffset.x < scrollView.bounds.size.width) {
        scrollView.contentOffset = CGPointMake(scrollView.bounds.size.width, 0);
    }
    if (_pageIndex == [self pageCount]-1 && scrollView.contentOffset.x > scrollView.bounds.size.width) {
        scrollView.contentOffset = CGPointMake(scrollView.bounds.size.width, 0);
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    if (_pageIndex == 0 && scrollView.contentOffset.x <= scrollView.bounds.size.width) {
        *targetContentOffset = CGPointMake(scrollView.bounds.size.width, 0);
    }
    if (_pageIndex == [self pageCount]-1 && scrollView.contentOffset.x >= scrollView.bounds.size.width) {
        *targetContentOffset = CGPointMake(scrollView.bounds.size.width, 0);
    }
}

/***********************************************/
/* COLLECTION VIEW EMBEDDER DATASOURCE METHODS */
/***********************************************/
-(NSUInteger)maxRowCount{
    return [_dataSource rowCountPerPageInDashboard:self];
}

-(NSUInteger)maxColumnCount{
    return [_dataSource columnCountPerPageInDashboard:self];
}

-(NSInteger)numberOfItemsInThisCollectionViewEmbedderViewController:(CollectionViewEmbedderViewController*)collectionViewEmbedderViewController{
    NSInteger numberOfItems;
    
    if([_dataSource cellCountInDashboard:self] == 0){
        return 0;
    }
    
    if(collectionViewEmbedderViewController.pageIndex == [self pageCount]-1){
        numberOfItems = [_dataSource cellCountInDashboard:self]%_onePageElementCount;
        if(numberOfItems == 0){
            numberOfItems = _onePageElementCount;
        }
    }else{
        numberOfItems = _onePageElementCount;
    }
    
    return numberOfItems;
}

-(UICollectionViewCell *)collectionViewEmbedderViewController:(CollectionViewEmbedderViewController*)collectionViewEmbedder cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    _lastWorkingOnCollectionViewEmbedder = collectionViewEmbedder;
    
    UICollectionViewCell* theCell = [_dataSource dashboard:self cellForItemAtIndex:indexPath.row+collectionViewEmbedder.pageIndex*_onePageElementCount];
    
    theCell.hidden = collectionViewEmbedder.pageIndex == [self pageOfThisIndex:_indexOfTheLastDraggedCellSource] && _indexOfTheLastDraggedCellSource%_onePageElementCount == indexPath.row && _draggedCell != nil;
    
    return theCell;
}

/*********************************************/
/* COLLECTION VIEW EMBEDDER DELEGATE METHODS */
/*********************************************/
- (void)collectionViewEmbedder:(CollectionViewEmbedderViewController *)collectionViewEmbedder didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if(_delegate != nil){
        if([_delegate respondsToSelector:@selector(dashboard:userTappedOnACellAtThisIndex:)]){
            [_delegate dashboard:self userTappedOnACellAtThisIndex:indexPath.row+collectionViewEmbedder.pageIndex*_onePageElementCount];
        }
    }
}

/*********************/
/* GESTURES MANAGING */
/*********************/
- (void)setUpGestures{
    [[KDashboardGestureManagerViewController sharedManager] registerDashboardForDragAndDrop:self];
}

-(void)removeGestures{
    [[KDashboardGestureManagerViewController sharedManager] unregisterDashboardForDragAndDrop:self];
}

- (void)handlePress:(UILongPressGestureRecognizer *)gesture{
    
    if(gesture.state == UIGestureRecognizerStateBegan){
        
        _lastTouchPoint = [gesture locationInView:_viewControllerEmbedder.view];
        _lastTimeDragChangedState = CFAbsoluteTimeGetCurrent();
        _insideDashboard = YES;
        
        UICollectionView* targetedCollectionView = _currentCollectionViewEmbedder.collectionView;
        CGPoint point = [gesture locationInView:targetedCollectionView];
        NSIndexPath *indexPath = [targetedCollectionView indexPathForItemAtPoint:point];
        if (indexPath != nil) {
            _indexOfTheLastDraggedCellSource = [self getDashboardIndexWithIndexPath:indexPath];
            [self showDraggedCellWithSourceCell:[targetedCollectionView cellForItemAtIndexPath:indexPath] fromThisStartPoint:[gesture locationInView:_viewControllerEmbedder.view]];
            if(_delegate != nil){
                if([_delegate respondsToSelector:@selector(dashboard:userStartedDragging:)]){
                    [_delegate dashboard:self userStartedDragging:_draggedCell];
                }
            }
        }
        
    }else if(gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed){
        [self cancelCanCreateAGroupTimer];
        if(!_movedDraggedCell){
            [_sourceDashboard == nil ? self : _sourceDashboard cancelDraggingAndGetDraggedCellBackToItsCellPosition];
        }else{
            _movedDraggedCell = NO;
        }
        
        if(_delegate != nil){
            if([_delegate respondsToSelector:@selector(endDraggingFromDashboard:)]){
                [_delegate endDraggingFromDashboard:self];
            }
        }
        
        if(_slidingWhileDraggingTimer != nil){
            [_slidingWhileDraggingTimer invalidate];
            _slidingWhileDraggingTimer = nil;
        }
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture{
    if(_draggedCell == nil){
        return;
    }
    
    if(gesture.state == UIGestureRecognizerStateChanged){
        _movedDraggedCell = YES;
        CGPoint point = [gesture locationInView:_viewControllerEmbedder.view];
        _draggedCell.center = point;
        
        if(CGRectContainsPoint(self.view.frame, point)){
            if(!_insideDashboard){
                if(_delegate != nil){
                    if([_delegate respondsToSelector:@selector(dashboard:userDraggedCellInsideDashboard:)]){
                        [_delegate dashboard:self userDraggedCellInsideDashboard:_draggedCell];
                    }
                }
                _insideDashboard = YES;
            }
        }else{
            if(_insideDashboard){
                if(_delegate != nil){
                    if([_delegate respondsToSelector:@selector(dashboard:userDraggedCellOutsideDashboard:)]){
                        [_delegate dashboard:self userDraggedCellOutsideDashboard:_draggedCell];
                    }
                }
                _insideDashboard = NO;
            }
        }
        
        if(_enableGroupCreation){
            if([self getDashboardCellIndexUnderDraggedCellWithGesture:gesture] == _indexOfTheLastDraggedCellSource){
                [self cancelCanCreateAGroupTimer];
                
                if(_canCreateGroup && _delegate != nil){
                    if([_delegate respondsToSelector:@selector(dismissGroupCreationPossibilityFromDashboard:)]){
                        [_delegate dismissGroupCreationPossibilityFromDashboard:self];
                    }
                    _canCreateGroup = NO;
                    _lastIndexWhereBeingAbleToCreateAGroup = -1;
                }
            }
            if(ABS(point.x-_lastTouchPoint.x)+ABS(point.y-_lastTouchPoint.y) > DISMISS_GROUP_CREATION_SENSIBILITY || _lastIndexWhereBeingAbleToCreateAGroup != [self getDashboardCellIndexUnderDraggedCellWithGesture:gesture]){
                _lastTimeDragChangedState = CFAbsoluteTimeGetCurrent();
                
                [self cancelCanCreateAGroupTimer];
                [self initiateCanCreateAGroupTimerWithGesture:gesture];
                
                if(_canCreateGroup && _delegate != nil){
                    if([_delegate respondsToSelector:@selector(dismissGroupCreationPossibilityFromDashboard:)]){
                        [_delegate dismissGroupCreationPossibilityFromDashboard:self];
                    }
                    _canCreateGroup = NO;
                    _lastIndexWhereBeingAbleToCreateAGroup = -1;
                }
            }
            _lastTouchPoint = point;
        }
        
        if(CGRectContainsPoint([self.view convertRect:_leftSideSlidingDetectionZone.frame toView:_viewControllerEmbedder.view], point)){
            [self cancelCanCreateAGroupTimer];
            _canCreateGroup = NO;
            _lastIndexWhereBeingAbleToCreateAGroup = -1;
            
            if(_slidingWhileDraggingTimer == nil){
                _slidingWhileDraggingTimer = [NSTimer scheduledTimerWithTimeInterval:_slidingPageWhileDraggingWaitingDuration
                                                                              target:self
                                                                            selector:@selector(slideToThePreviousPage)
                                                                            userInfo:nil
                                                                             repeats:YES];
            }
        }else if(CGRectContainsPoint([self.view convertRect:_rightSideSlidingDetectionZone.frame toView:_viewControllerEmbedder.view], point)){
            [self cancelCanCreateAGroupTimer];
            _canCreateGroup = NO;
            _lastIndexWhereBeingAbleToCreateAGroup = -1;
            
            if(_slidingWhileDraggingTimer == nil){
                _slidingWhileDraggingTimer = [NSTimer scheduledTimerWithTimeInterval:_slidingPageWhileDraggingWaitingDuration
                                                                              target:self
                                                                            selector:@selector(slideToTheNextPage)
                                                                            userInfo:nil
                                                                             repeats:YES];
            }
        }else if(_slidingWhileDraggingTimer != nil){
            [_slidingWhileDraggingTimer invalidate];
            _slidingWhileDraggingTimer = nil;
        }
    }
    
    if(gesture.state == UIGestureRecognizerStateRecognized){
        [self cancelCanCreateAGroupTimer];
        CGPoint droppingPoint = [gesture locationInView:_currentCollectionViewEmbedder.collectionView];
        NSIndexPath* indexPath = [_currentCollectionViewEmbedder.collectionView indexPathForItemAtPoint:droppingPoint];
        UICollectionViewCell* targetedCell = [self getCellAtDashboardIndex:[self getDashboardIndexWithIndexPath:indexPath]];
        
        if(indexPath != nil && _indexOfTheLastDraggedCellSource != [self getDashboardIndexWithIndexPath:indexPath] && _insideDashboard){
            if(_enableGroupCreation && CFAbsoluteTimeGetCurrent()-_lastTimeDragChangedState > _minimumWaitingDurationToCreateAGroup && [self getDashboardCellIndexUnderDraggedCellWithGesture:gesture] != _indexOfTheLastDraggedCellSource){
                [self addGroupAtIndex:[self getDashboardIndexWithIndexPath:indexPath] withCellAtIndex:_indexOfTheLastDraggedCellSource];
                return;
            }else if(_enableInsertingAction && ([self isInsertingToTheLeftOfThisCell:targetedCell atThisPoint:droppingPoint]||[self isInsertingToTheRightOfThisCell:targetedCell atThisPoint:droppingPoint])){
                [self insertCellFromIndex:_sourceDashboard == nil ? _indexOfTheLastDraggedCellSource : _sourceDashboard.indexOfTheLastDraggedCellSource toIndex:[self getDashboardIndexWithIndexPath:indexPath]+(int)[self isInsertingToTheRightOfThisCell:targetedCell atThisPoint:droppingPoint]];
                return;
            }else if(_enableSwappingAction){
                [self swapCellAtIndex:_sourceDashboard == nil ? _indexOfTheLastDraggedCellSource : _sourceDashboard.indexOfTheLastDraggedCellSource withCellAtIndex:[self getDashboardIndexWithIndexPath:indexPath]];
                return;
            }
        }else if(_deleteZone != nil){
            if(CGRectContainsPoint(_deleteZone.frame, [_currentCollectionViewEmbedder.collectionView convertPoint:droppingPoint toView:_viewControllerEmbedder.view])){
                [self deleteCellAtIndex:_indexOfTheLastDraggedCellSource];
                return;
            }
        }
    }
    
    if(gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateEnded|| gesture.state == UIGestureRecognizerStateFailed || gesture.state == UIGestureRecognizerStateRecognized){
        
        [_sourceDashboard == nil ? self : _sourceDashboard cancelDraggingAndGetDraggedCellBackToItsCellPosition];
    }
}

-(void)canCreateAGroup{
    _canCreateGroup = YES;
    if(_delegate != nil){
        if([_delegate respondsToSelector:@selector(dashboard:canCreateGroupAtIndex:withSourceIndex:)]){
            [_delegate dashboard:self canCreateGroupAtIndex:_lastIndexWhereBeingAbleToCreateAGroup withSourceIndex:_indexOfTheLastDraggedCellSource];
        }
    }
}

-(void) initiateCanCreateAGroupTimerWithGesture:(UIPanGestureRecognizer*)gesture{
    NSInteger indexWhereBeingAbleToCreateAGroup = [self getDashboardCellIndexUnderDraggedCellWithGesture:gesture];
    if(indexWhereBeingAbleToCreateAGroup >= 0){
        _lastIndexWhereBeingAbleToCreateAGroup = indexWhereBeingAbleToCreateAGroup;
        _canCreateGroupTimer = [NSTimer scheduledTimerWithTimeInterval:_minimumWaitingDurationToCreateAGroup
                                                                target:self
                                                              selector:@selector(canCreateAGroup)
                                                              userInfo:nil
                                                               repeats:NO];
    }
}

-(void) cancelCanCreateAGroupTimer{
    if(_canCreateGroupTimer != nil){
        [_canCreateGroupTimer invalidate];
        _canCreateGroupTimer = nil;
    }
}

-(NSInteger)getDashboardCellIndexUnderDraggedCellWithGesture:(UIPanGestureRecognizer*)gesture{
    NSIndexPath* indexPathUnderDraggedCell = [_currentCollectionViewEmbedder.collectionView indexPathForItemAtPoint:[gesture locationInView:_currentCollectionViewEmbedder.collectionView]];
    if(indexPathUnderDraggedCell != nil){
        return [self getDashboardIndexWithIndexPath:indexPathUnderDraggedCell];
    }
    return -1;
}

/*************************/
/* DRAGGED CELL MANAGING */
/*************************/
-(void) showDraggedCellWithSourceCell:(UICollectionViewCell*)cell fromThisStartPoint:(CGPoint)startPoint{
    _memorizedDraggedCellSourceCenter = cell.center;
    
    _draggedCell = [cell snapshotViewAfterScreenUpdates:YES];
    cell.hidden = YES;
    
    _draggedCell.center = startPoint;
    [_viewControllerEmbedder.view addSubview:_draggedCell];
}

-(void) moveCellWithCellSource:(UICollectionViewCell*)cell toPreviousOrNextPage:(BOOL)previous withDestinationPoint:(CGPoint)destinationPoint{
    
    [self moveCellWithCellSource:cell toDestinationPoint:CGPointMake(destinationPoint.x+(previous ? -self.view.frame.size.width : self.view.frame.size.width), destinationPoint.y)];
}

-(void) moveCellWithCellSource:(UICollectionViewCell*)cell toDestinationPoint:(CGPoint)destinationPoint{
    _bufferMovingCell = [cell snapshotViewAfterScreenUpdates:YES];
    cell.hidden = YES;
    
    _bufferMovingCell.center = [self.view convertPoint:cell.center toView:nil];
    [_viewControllerEmbedder.view addSubview:_bufferMovingCell];
    
    destinationPoint = [self.view convertPoint:destinationPoint toView:nil];
    
    [UIView animateWithDuration:CANCEL_DRAGGING_ANIMATION_DURATION
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _bufferMovingCell.center = destinationPoint;
                     }
                     completion:^(BOOL finished){
                         cell.hidden = NO;
                         
                         [_bufferMovingCell removeFromSuperview];
                         _bufferMovingCell = nil;
                         
                         [_currentCollectionViewEmbedder.collectionView reloadData];
                     }];
}

-(void) bringFirstIndexCellFromNextPageToLastIndexOfCurrentPage{
    UICollectionViewCell* cellFromNextPage = [_dataSource dashboard:self cellForItemAtIndex:_onePageElementCount*(_pageIndex+1)-1];
    _bufferMovingCell = [cellFromNextPage snapshotViewAfterScreenUpdates:YES];
    cellFromNextPage.hidden = YES;
    _bufferMovingCell.center = [self.view convertPoint:CGPointMake(_calculatedFirstElementCenter.x+_pageViewController.view.frame.size.width, _calculatedFirstElementCenter.y) toView:nil];
    [_viewControllerEmbedder.view addSubview:_bufferMovingCell];
    
    [UIView animateWithDuration:CANCEL_DRAGGING_ANIMATION_DURATION
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _bufferMovingCell.center = [self.view convertPoint:_calculatedLastElementCenter toView:nil];
                     }
                     completion:^(BOOL finished){
                         
                         cellFromNextPage.hidden = NO;
                         
                         [_bufferMovingCell removeFromSuperview];
                         _bufferMovingCell = nil;
                         
                         _indexOfTheLastDraggedCellSource = -1;
                         
                         [_currentCollectionViewEmbedder.collectionView reloadData];
                     }];
}

-(void) hideDraggedCellAndRestoreCellAtDashboardIndex:(NSInteger)index{
    KDashboard* effectiveDashboard = _sourceDashboard == nil ? self : _sourceDashboard;
    UICollectionViewCell* lastDraggedCellSource = [effectiveDashboard getCellAtDashboardIndex:index];
    
    if(lastDraggedCellSource != nil){
        lastDraggedCellSource.hidden = NO;
    }
    [effectiveDashboard.draggedCell removeFromSuperview];
    effectiveDashboard.draggedCell = nil;
    
    effectiveDashboard.indexOfTheLastDraggedCellSource = -1;
}

-(void) hideDraggedCellWithCompletionBlock:(void(^)(void))completionBlock{
    [UIView animateWithDuration:DELETE_CELL_DISAPPEAR_ANIMATION_DURATION
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _draggedCell.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         [self hideDraggedCellAndRestoreCellAtDashboardIndex:_indexOfTheLastDraggedCellSource];
                         
                         [_currentCollectionViewEmbedder.collectionView reloadData];
                         
                         if(completionBlock != nil)completionBlock();
                     }];
}

-(void) cancelDraggingAndGetDraggedCellBackToItsCellPosition{
    [self cancelDraggingAndMoveDraggedCellToThisDashboardIndex:_indexOfTheLastDraggedCellSource];
}

-(void) cancelDraggingAndMoveDraggedCellToThisDashboardIndex:(NSInteger)index{
    [UIView animateWithDuration:CANCEL_DRAGGING_ANIMATION_DURATION
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _draggedCell.center = [self calculateCellPositionOfThisDashboardIndex:index];
                     }
                     completion:^(BOOL finished){
                         [self hideDraggedCellAndRestoreCellAtDashboardIndex:index];
                     }];
}

-(void) cancelDraggingAndMoveDraggedCellToThisDestinationPoint:(CGPoint)destinationPoint withCompletionBlock:(void(^)(void))completionBlock{
    [UIView animateWithDuration:CANCEL_DRAGGING_ANIMATION_DURATION
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _draggedCell.center = destinationPoint;
                     }
                     completion:^(BOOL finished){
                         [self hideDraggedCellAndRestoreCellAtDashboardIndex:_indexOfTheLastDraggedCellSource];
                         
                         [_currentCollectionViewEmbedder.collectionView reloadData];
                         
                         if(completionBlock != nil)completionBlock();
                     }];
}

-(CGPoint) calculateCellPositionOfThisDashboardIndex:(NSInteger)index{
    CGPoint cellPosition;
    
    KDashboard* effectiveDashboard = _sourceDashboard == nil ? self : _sourceDashboard;
    
    if([effectiveDashboard pageOfThisIndex:index] == effectiveDashboard.pageIndex){
        cellPosition = [effectiveDashboard getCellAtDashboardIndex:index].center;
        cellPosition.x -= effectiveDashboard.currentCollectionViewEmbedder.collectionView.contentOffset.x;
        cellPosition.y -= effectiveDashboard.currentCollectionViewEmbedder.collectionView.contentOffset.y;
    }else{
        NSInteger maxColumnCount, maxRowCount;
        if([effectiveDashboard.dataSource rowCountPerPageInDashboard:effectiveDashboard] == 0 && [effectiveDashboard.dataSource columnCountPerPageInDashboard:effectiveDashboard] == 0){
            maxColumnCount = DEFAULT_MAX_COLUMN_ROW_COUNT;
            maxRowCount = DEFAULT_MAX_COLUMN_ROW_COUNT;
        }else{
            maxColumnCount = [effectiveDashboard.dataSource columnCountPerPageInDashboard:effectiveDashboard] == 0 ? [effectiveDashboard.dataSource rowCountPerPageInDashboard:effectiveDashboard] : [effectiveDashboard.dataSource columnCountPerPageInDashboard:effectiveDashboard];
            maxRowCount = [effectiveDashboard.dataSource rowCountPerPageInDashboard:effectiveDashboard] == 0 ? [effectiveDashboard.dataSource columnCountPerPageInDashboard:effectiveDashboard] : [effectiveDashboard.dataSource rowCountPerPageInDashboard:effectiveDashboard];
        }
        
        NSInteger indexInItsPage = index-[effectiveDashboard pageOfThisIndex:index]*effectiveDashboard.onePageElementCount;
        NSInteger row = indexInItsPage/maxRowCount;
        NSInteger column = indexInItsPage/maxColumnCount;
        
        cellPosition = CGPointMake(column*effectiveDashboard.oneElementWidth+effectiveDashboard.oneElementWidth/2, row*effectiveDashboard.oneElementHeight+effectiveDashboard.oneElementHeight/2);
        
        if([effectiveDashboard pageOfThisIndex:index] < effectiveDashboard.pageIndex){
            cellPosition.x -= effectiveDashboard.view.frame.size.width;
        }else{
            cellPosition.x += effectiveDashboard.view.frame.size.width;
        }
    }
    
    return [effectiveDashboard.view convertPoint:cellPosition toView:nil];
}

/**************************/
/* SLIDING PAGES MANAGING */
/**************************/
-(void) slideToThePreviousPage{
    if(_pageIndex <= 0 || _draggedCell == nil){
        if(_slidingWhileDraggingTimer != nil){
            [_slidingWhileDraggingTimer invalidate];
            _slidingWhileDraggingTimer = nil;
        }
    }else{
        [self pageViewController:_pageViewController switchToThisViewController:(CollectionViewEmbedderViewController*)[self pageViewController:_pageViewController viewControllerBeforeViewController:_currentCollectionViewEmbedder] withDirection:UIPageViewControllerNavigationDirectionReverse];
    }
}

-(void) slideToTheNextPage{
    if(_pageIndex >= [self pageCount]-1 || _draggedCell == nil){
        if(_slidingWhileDraggingTimer != nil){
            [_slidingWhileDraggingTimer invalidate];
            _slidingWhileDraggingTimer = nil;
        }
    }else{
        [self pageViewController:_pageViewController switchToThisViewController:(CollectionViewEmbedderViewController*)[self pageViewController:_pageViewController viewControllerAfterViewController:_currentCollectionViewEmbedder] withDirection:UIPageViewControllerNavigationDirectionForward];
    }
}

/*************************/
/* DROPPED CELL MANAGING */
/*************************/
//SWAP//
-(void)swapCellAtIndex:(NSInteger)sourceIndex withCellAtIndex:(NSInteger)destinationIndex{
    if(_sourceDashboard != nil){
        if(_enableSwappingActionFromAnotherDashboard){
            if(_delegate != nil){
                if([_delegate respondsToSelector:@selector(dashboard:swapCellAtIndex:withCellAtIndex:fromAnotherDashboard:)]){
                    if(![_delegate dashboard:self swapCellAtIndex:sourceIndex withCellAtIndex:destinationIndex fromAnotherDashboard:_sourceDashboard]){
                        if([[KDashboardGestureManagerViewController sharedManager] knowsThisDashboard:_sourceDashboard]){
                            [_sourceDashboard cancelDraggingAndGetDraggedCellBackToItsCellPosition];
                        }else{
                            [_sourceDashboard hideDraggedCellWithCompletionBlock:nil];
                        }
                        return;
                    }
                    
                    if(![[KDashboardGestureManagerViewController sharedManager] knowsThisDashboard:_sourceDashboard]){
                        
                        [UIView animateWithDuration:CANCEL_DRAGGING_ANIMATION_DURATION
                                         animations:^{
                                             [self cellAtDashboardIndex:destinationIndex].alpha = 0;
                                         }
                                         completion:^(BOOL finished){
                                             [self cellAtDashboardIndex:destinationIndex].alpha = 1;
                                         }];
                        
                        [_sourceDashboard cancelDraggingAndMoveDraggedCellToThisDestinationPoint:[self.view convertPoint:[self cellAtDashboardIndex:destinationIndex].center toView:_viewControllerEmbedder.view] withCompletionBlock:^{
                            [self cellAtDashboardIndex:destinationIndex].hidden = YES;
                            [_currentCollectionViewEmbedder.collectionView performBatchUpdates:^{
                                [_currentCollectionViewEmbedder.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:destinationIndex%_onePageElementCount inSection:0]]];
                            }completion:^(BOOL finished){
                                [self cellAtDashboardIndex:destinationIndex].hidden = NO;
                            }];
                        }];
                        
                        return;
                    }
                    
                    NSInteger pageIndexOfSourceCell = [_sourceDashboard pageOfThisIndex:sourceIndex];
                    NSInteger currentPageIndexOfSourceDashboard = _sourceDashboard.pageIndex;
                        
                    if(pageIndexOfSourceCell != currentPageIndexOfSourceDashboard){
                        [self moveCellWithCellSource:[self cellAtDashboardIndex:destinationIndex] toPreviousOrNextPage:(pageIndexOfSourceCell < currentPageIndexOfSourceDashboard) withDestinationPoint:[_sourceDashboard.view convertPoint:_sourceDashboard.memorizedDraggedCellSourceCenter toView:self.view]];
                        [_sourceDashboard cancelDraggingAndMoveDraggedCellToThisDestinationPoint:[self.view convertPoint:[self cellAtDashboardIndex:destinationIndex].center toView:_viewControllerEmbedder.view] withCompletionBlock:nil];
                    }else{
                        [self moveCellWithCellSource:[self cellAtDashboardIndex:destinationIndex] toDestinationPoint:[self.view convertPoint:[_sourceDashboard cellAtDashboardIndex:sourceIndex].center fromView:_sourceDashboard.view]];
                        [_sourceDashboard cancelDraggingAndMoveDraggedCellToThisDestinationPoint:[self.view convertPoint:[self cellAtDashboardIndex:destinationIndex].center toView:_viewControllerEmbedder.view] withCompletionBlock:nil];
                    }
                    
                    return;
                }
            }
        }
        
        if([[KDashboardGestureManagerViewController sharedManager] knowsThisDashboard:_sourceDashboard]){
            [_sourceDashboard cancelDraggingAndGetDraggedCellBackToItsCellPosition];
        }else{
            [_sourceDashboard hideDraggedCellWithCompletionBlock:nil];
        }
        
        return;
    }
    
    if(sourceIndex == destinationIndex){
        [self cancelDraggingAndGetDraggedCellBackToItsCellPosition];
        return;
    }
    
    if(_delegate != nil){
        if([_delegate respondsToSelector:@selector(dashboard:swapCellAtIndex:withCellAtIndex:)]){
            [_delegate dashboard:self swapCellAtIndex:sourceIndex withCellAtIndex:destinationIndex];
        }
    }
    
    UICollectionView* targetedCollectionView = _currentCollectionViewEmbedder.collectionView;
    
    NSIndexPath* sourceIndexPath = [NSIndexPath indexPathForRow:sourceIndex%_onePageElementCount inSection:0];
    NSIndexPath* destinationIndexPath = [NSIndexPath indexPathForRow:destinationIndex%_onePageElementCount inSection:0];
    
    NSInteger pageIndexOfSourceCell = [self pageOfThisIndex:sourceIndex];
    NSInteger pageIndexOfDestinationCell = [self pageOfThisIndex:destinationIndex];
    
    if(pageIndexOfSourceCell == pageIndexOfDestinationCell){
        [targetedCollectionView performBatchUpdates:^{
            [targetedCollectionView moveItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
            [targetedCollectionView moveItemAtIndexPath:destinationIndexPath toIndexPath:sourceIndexPath];
        }completion:^(BOOL finished){
            
        }];
    }else{
        [self moveCellWithCellSource:[_currentCollectionViewEmbedder.collectionView cellForItemAtIndexPath:destinationIndexPath] toPreviousOrNextPage:(pageIndexOfSourceCell < pageIndexOfDestinationCell) withDestinationPoint:_memorizedDraggedCellSourceCenter];
    }
    
    [self cancelDraggingAndMoveDraggedCellToThisDashboardIndex:destinationIndex];
}

//INSERT//
-(BOOL) isInsertingToTheLeftOfThisCell:(UICollectionViewCell*)cell atThisPoint:(CGPoint)droppingPoint{
    CGFloat asideCellInsertingZoneWidthPercentage = _enableSwappingAction ? ASIDE_CELL_INSERTING_ZONE_WIDTH_PERCENTAGE : 50;
    
    CGRect cellFrame = cell.frame;
    cellFrame.size.width = cellFrame.size.width*asideCellInsertingZoneWidthPercentage/100;
    
    return CGRectContainsPoint(cellFrame, droppingPoint);
}

-(BOOL) isInsertingToTheRightOfThisCell:(UICollectionViewCell*)cell atThisPoint:(CGPoint)droppingPoint{
    CGFloat asideCellInsertingZoneWidthPercentage = _enableSwappingAction ? ASIDE_CELL_INSERTING_ZONE_WIDTH_PERCENTAGE : 50;
    
    CGRect cellFrame = cell.frame;
    cellFrame.origin.x += cellFrame.size.width*(100-asideCellInsertingZoneWidthPercentage)/100;
    cellFrame.size.width = cellFrame.size.width*asideCellInsertingZoneWidthPercentage/100;
    
    return CGRectContainsPoint(cellFrame, droppingPoint);
}

-(void)insertCellFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex{
    if(_sourceDashboard != nil){
        if(_enableInsertingActionFromAnotherDashboard){
            if(_delegate != nil){
                if([_delegate respondsToSelector:@selector(dashboard:insertCellFromIndex:toIndex:fromAnotherDashboard:)]){
                    NSInteger prevPageCount = [self pageCount];
                    NSInteger sourcePrevPageCount = [_sourceDashboard pageCount];
                    
                    if(![_delegate dashboard:self insertCellFromIndex:sourceIndex toIndex:destinationIndex fromAnotherDashboard:_sourceDashboard]){
                        if([[KDashboardGestureManagerViewController sharedManager] knowsThisDashboard:_sourceDashboard]){
                            [_sourceDashboard cancelDraggingAndGetDraggedCellBackToItsCellPosition];
                        }else{
                            [_sourceDashboard hideDraggedCellWithCompletionBlock:nil];
                        }
                        
                        return;
                    }
                    
                    //DESTINATION DASHBOARD
                    if([self pageCount] > prevPageCount){
                        [self hideDraggedCellWithCompletionBlock:nil];
                        
                        [self loadInitialViewControllerAtIndex:_pageIndex withAnimation:NO andDirection:UIPageViewControllerNavigationDirectionForward andCompletionBlock:nil];
                    }else{
                        if([self getCellCountForCurrentPage] == _onePageElementCount){
                            [self moveCellWithCellSource:[_currentCollectionViewEmbedder.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:[self getCellCountForCurrentPage]-1 inSection:0]] toPreviousOrNextPage:NO withDestinationPoint:_calculatedFirstElementCenter];
                            [_currentCollectionViewEmbedder.collectionView performBatchUpdates:^{
                                [_currentCollectionViewEmbedder.collectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:[self getCellCountForCurrentPage]-1 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:destinationIndex%_onePageElementCount inSection:0]];
                            }completion:^(BOOL finished){
                                
                            }];
                        }else{
                            [_currentCollectionViewEmbedder.collectionView performBatchUpdates:^{
                                [_currentCollectionViewEmbedder.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:destinationIndex%_onePageElementCount inSection:0]]];
                            }completion:^(BOOL finished){
                                [_currentCollectionViewEmbedder.collectionView reloadData];
                            }];
                        }
                        [_sourceDashboard cancelDraggingAndMoveDraggedCellToThisDestinationPoint:[self.view convertPoint:[self cellAtDashboardIndex:destinationIndex].center toView:_viewControllerEmbedder.view] withCompletionBlock:nil];
                    }
                    
                    //SOURCE DASHBOARD
                    if(![[KDashboardGestureManagerViewController sharedManager] knowsThisDashboard:_sourceDashboard]){
                        [_currentCollectionViewEmbedder.collectionView reloadData];
                        return;
                    }
                    
                    if([_sourceDashboard pageCount] < sourcePrevPageCount){
                        NSInteger loadViewControllerAtIndex = _sourceDashboard.pageIndex;
                        BOOL animated = NO;
                        if(_sourceDashboard.pageIndex == [_sourceDashboard pageCount]){
                            loadViewControllerAtIndex = _sourceDashboard.pageIndex-1;
                            animated = YES;
                        }
                        
                        [_sourceDashboard loadInitialViewControllerAtIndex:loadViewControllerAtIndex withAnimation:animated andDirection:UIPageViewControllerNavigationDirectionReverse andCompletionBlock:nil];
                    }else{
                        NSInteger pageIndexOfSourceCell = [_sourceDashboard pageOfThisIndex:sourceIndex];
                        NSInteger currentPageIndexOfSourceDashboard = _sourceDashboard.pageIndex;
                        
                        if(pageIndexOfSourceCell < currentPageIndexOfSourceDashboard){
                            [_sourceDashboard moveCellWithCellSource:[_sourceDashboard.currentCollectionViewEmbedder.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] toPreviousOrNextPage:YES withDestinationPoint:_sourceDashboard.calculatedLastElementCenter];
                            [_sourceDashboard bringFirstIndexCellFromNextPageToLastIndexOfCurrentPage];
                            [_sourceDashboard.currentCollectionViewEmbedder.collectionView performBatchUpdates:^{
                                [_sourceDashboard.currentCollectionViewEmbedder.collectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:_sourceDashboard.onePageElementCount-1 inSection:0]];
                            }completion:^(BOOL finished){
                                
                            }];
                        }else if(pageIndexOfSourceCell == currentPageIndexOfSourceDashboard){
                            if(_sourceDashboard.pageIndex == [_sourceDashboard pageCount]-1){
                                [_sourceDashboard.currentCollectionViewEmbedder.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:sourceIndex%_sourceDashboard.onePageElementCount inSection:0]]];
                            }else{
                                [_sourceDashboard.currentCollectionViewEmbedder.collectionView performBatchUpdates:^{
                                    [_sourceDashboard.currentCollectionViewEmbedder.collectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:sourceIndex%_sourceDashboard.onePageElementCount inSection:0] toIndexPath:[NSIndexPath indexPathForRow:[_sourceDashboard getCellCountForCurrentPage]-1 inSection:0]];
                                }completion:^(BOOL finished){
                                    
                                }];
                                
                                [_sourceDashboard bringFirstIndexCellFromNextPageToLastIndexOfCurrentPage];
                            }
                        }
                    }
                    
                    return;
                }
            }
        }
        [_sourceDashboard cancelDraggingAndGetDraggedCellBackToItsCellPosition];
        return;
    }
    
    if(sourceIndex == destinationIndex){
        [self cancelDraggingAndGetDraggedCellBackToItsCellPosition];
        return;
    }
    
    if(_delegate != nil){
        if([_delegate respondsToSelector:@selector(dashboard:insertCellFromIndex:toIndex:)]){
            if(![_delegate dashboard:self insertCellFromIndex:sourceIndex toIndex:(sourceIndex < destinationIndex) ? destinationIndex-1 : destinationIndex]){
                [_sourceDashboard cancelDraggingAndGetDraggedCellBackToItsCellPosition];
                return;
            }
        }
    }
    
    UICollectionView* currentCollectionView = _currentCollectionViewEmbedder.collectionView;
    
    if(sourceIndex < destinationIndex){
        destinationIndex--;
        
        [self cancelDraggingAndMoveDraggedCellToThisDashboardIndex:destinationIndex];
        
        if([self pageOfThisIndex:destinationIndex] != _pageIndex){
            return;
        }
        
        if([self pageOfThisIndex:sourceIndex] != _currentCollectionViewEmbedder.pageIndex){
            [self moveCellWithCellSource:[currentCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] toPreviousOrNextPage:YES withDestinationPoint:_calculatedLastElementCenter];
            [currentCollectionView performBatchUpdates:^{
                [currentCollectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:destinationIndex%_onePageElementCount inSection:0]];
                
            }completion:^(BOOL finished){
                
            }];
        }else{
            [currentCollectionView performBatchUpdates:^{
                [currentCollectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:sourceIndex%_onePageElementCount inSection:0] toIndexPath:[NSIndexPath indexPathForRow:destinationIndex%_onePageElementCount inSection:0]];
            }completion:^(BOOL finished){
                
            }];
        }
    }else{
        [self cancelDraggingAndMoveDraggedCellToThisDashboardIndex:destinationIndex];
        
        if([self pageOfThisIndex:destinationIndex] != _pageIndex){
            return;
        }
        
        if([self pageOfThisIndex:sourceIndex] != _currentCollectionViewEmbedder.pageIndex){
            [self moveCellWithCellSource:[currentCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:[self getCellCountForCurrentPage]-1 inSection:0]] toPreviousOrNextPage:NO withDestinationPoint:_calculatedFirstElementCenter];
            [currentCollectionView performBatchUpdates:^{
                [currentCollectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:[self getCellCountForCurrentPage]-1 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:destinationIndex%_onePageElementCount inSection:0]];
                
            }completion:^(BOOL finished){
                
            }];
        }else{
            [currentCollectionView performBatchUpdates:^{
                [currentCollectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:sourceIndex%_onePageElementCount inSection:0] toIndexPath:[NSIndexPath indexPathForRow:destinationIndex%_onePageElementCount inSection:0]];
            }completion:^(BOOL finished){
                
            }];
        }
    }
}

//DELETE//
-(void)deleteCellAtIndex:(NSInteger)index{
    if(_delegate != nil){
        if([_delegate respondsToSelector:@selector(dashboard:deleteCellAtIndex:)]){
            NSInteger prevPageCount = [self pageCount];
            
            if(![_delegate dashboard:self deleteCellAtIndex:index]){
                [_sourceDashboard cancelDraggingAndGetDraggedCellBackToItsCellPosition];
                return;
            }
            
            if([self pageCount] < prevPageCount){
                [self hideDraggedCellWithCompletionBlock:nil];
                
                NSInteger loadViewControllerAtIndex = _pageIndex;
                BOOL animated = NO;
                if(_pageIndex == [self pageCount]){
                    loadViewControllerAtIndex = _pageIndex-1;
                    animated = YES;
                }
                
                [self loadInitialViewControllerAtIndex:loadViewControllerAtIndex withAnimation:animated andDirection:UIPageViewControllerNavigationDirectionReverse andCompletionBlock:nil];
                
                return;
            }
            
            NSInteger pageOfDeletedCell = [self pageOfThisIndex:index];
            UICollectionView* currentCollectionView = _currentCollectionViewEmbedder.collectionView;
            
            [self hideDraggedCellWithCompletionBlock:nil];
            
            if(pageOfDeletedCell == _pageIndex){
                
                if(_pageIndex == [self pageCount]-1){
                    [currentCollectionView performBatchUpdates:^{
                        [currentCollectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:index%_onePageElementCount inSection:0]]];
                    }completion:^(BOOL finished){
                        
                    }];
                }else{
                    [self bringFirstIndexCellFromNextPageToLastIndexOfCurrentPage];
                    
                    [currentCollectionView performBatchUpdates:^{
                        [currentCollectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:index%_onePageElementCount inSection:0] toIndexPath:[NSIndexPath indexPathForRow:_onePageElementCount-1 inSection:0]];
                    }completion:^(BOOL finished){
                        
                    }];
                }
                
            }else if(pageOfDeletedCell < _pageIndex){
                if(_pageIndex == [self pageCount]-1){
                    [self moveCellWithCellSource:[currentCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] toPreviousOrNextPage:YES withDestinationPoint:_calculatedLastElementCenter];
                    [currentCollectionView performBatchUpdates:^{
                        [currentCollectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:index%_onePageElementCount inSection:0]]];
                    }completion:^(BOOL finished){
                        
                    }];
                }else{
                    [self moveCellWithCellSource:[currentCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] toPreviousOrNextPage:YES withDestinationPoint:_calculatedLastElementCenter];
                    [self bringFirstIndexCellFromNextPageToLastIndexOfCurrentPage];
                    [currentCollectionView performBatchUpdates:^{
                        [currentCollectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:_onePageElementCount-1 inSection:0]];
                    }completion:^(BOOL finished){
                        
                    }];
                }
            }
            
        }else{
            [self cancelDraggingAndGetDraggedCellBackToItsCellPosition];
        }
    }else{
        [self cancelDraggingAndGetDraggedCellBackToItsCellPosition];
    }
}

//CREATE_GROUP
-(void) addGroupAtIndex:(NSInteger)index withCellAtIndex:(NSInteger)sourceIndex{
    if(_canCreateGroup && _delegate != nil){
        if([_delegate respondsToSelector:@selector(dismissGroupCreationPossibilityFromDashboard:)]){
            [_delegate dismissGroupCreationPossibilityFromDashboard:self];
        }
        _canCreateGroup = NO;
        _lastIndexWhereBeingAbleToCreateAGroup = -1;
    }
    
    if(_delegate != nil){
        if([_delegate respondsToSelector:@selector(dashboard:addGroupAtIndex:withCellAtIndex:)]){
            [_delegate dashboard:self addGroupAtIndex:index withCellAtIndex:sourceIndex];
            
            [self hideDraggedCellWithCompletionBlock:nil];
        }else{
            [self cancelDraggingAndGetDraggedCellBackToItsCellPosition];
        }
    }else{
        [self cancelDraggingAndGetDraggedCellBackToItsCellPosition];
    }
}

/********************/
/* INDEXES MANAGING */
/********************/
-(NSUInteger) pageCount{
    return ceil((float)[_dataSource cellCountInDashboard:self]/(float)_onePageElementCount);
}

-(NSUInteger) pageOfThisIndex:(NSInteger)index{
    return index/_onePageElementCount;
}

-(NSInteger) getDashboardIndexWithIndexPath:(NSIndexPath*)indexPath{
    return indexPath.row+_pageIndex*_onePageElementCount;
}

-(UICollectionViewCell*)getLastDraggedCellSource{
    return [self getCellAtDashboardIndex:_indexOfTheLastDraggedCellSource];
}

-(UICollectionViewCell*)getCellAtDashboardIndex:(NSInteger)index{
    if([self pageOfThisIndex:index] == _pageIndex){
        return [_currentCollectionViewEmbedder.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index%_onePageElementCount inSection:0]];
    }
    
    return nil;
}

-(NSInteger)getCellCountForCurrentPage{
    return _currentCollectionViewEmbedder.collectionView.visibleCells.count;
}

/*******************/
/* OPTIONS METHODS */
/*******************/
-(void) setBounces:(BOOL)bounces{
    _bounces = bounces;
    
    if(bounces){
        _theScrollView.delegate = nil;
        _theScrollView = nil;
    }else{
        for(UIView* subview in _pageViewController.view.subviews){
            if([subview isKindOfClass:[UIScrollView class]]){
                _theScrollView = (UIScrollView*)subview;
                _theScrollView.delegate = self;
            }
        }
    }
}

-(void) setShowPageControlWhenOnlyOnePage:(BOOL)showPageControlWhenOnlyOnePage{
    _showPageControlWhenOnlyOnePage = showPageControlWhenOnlyOnePage;
    [self reloadNumberOfPages];
}

-(void) setShowPageControl:(BOOL)showPageControl{
    _showPageControl = showPageControl;
    [self layoutSubviews];
}

-(void) setEnableDragAndDrop:(BOOL)enableDragAndDrop{
    _enableDragAndDrop = enableDragAndDrop;
    if(enableDragAndDrop){
        [self setUpGestures];
    }else{
        [self removeGestures];
    }
}

-(void) setEnableSwappingAction:(BOOL)enableSwappingAction{
    _enableSwappingAction = enableSwappingAction;
}

-(void) setEnableInsertingAction:(BOOL)enableInsertingAction{
    _enableInsertingAction = enableInsertingAction;
}

-(void) setEnableGroupCreation:(BOOL)enableGroupCreation{
    _enableGroupCreation = enableGroupCreation;
}

-(void) setMinimumPressDurationToStartDragging:(CGFloat)minimumPressDurationToStartDragging{
    if(minimumPressDurationToStartDragging < 0) minimumPressDurationToStartDragging = 0;
    _minimumPressDurationToStartDragging = minimumPressDurationToStartDragging;
    
    [[KDashboardGestureManagerViewController sharedManager] setMinimumPressDurationToStartDragging:minimumPressDurationToStartDragging];
}

-(void) setSlidingPageWhileDraggingWaitingDuration:(CGFloat)slidingPageWhileDraggingWaitingDuration{
    _slidingPageWhileDraggingWaitingDuration = slidingPageWhileDraggingWaitingDuration;
}

-(void) setMinimumWaitingDurationToCreateAGroup:(CGFloat)minimumWaitingDurationToCreateAGroup{
    _minimumWaitingDurationToCreateAGroup = minimumWaitingDurationToCreateAGroup;
}

/****************/
/* USER METHODS */
/****************/
-(void) associateADeleteZone:(UIView*)deleteZone{
    _deleteZone = deleteZone;
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index{
    return [_lastWorkingOnCollectionViewEmbedder dequeueReusableCellWithIdentifier:identifier forIndex:index];
}

-(UICollectionViewCell*)cellAtDashboardIndex:(NSInteger)index{
    return [self getCellAtDashboardIndex:index];
}

-(void) reloadData{
    [_currentCollectionViewEmbedder.collectionView reloadData];
}

@end
