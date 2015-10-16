//
//  KDashboard.m
//  KDashboard
//
//  Created by COURELJordan on 13/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import "KDashboard.h"

#define IS_IOS7 ([[[UIDevice currentDevice] systemVersion] floatValue] == 7.0)

#define PAGE_VIEW_CONTROLLER_HEIGHT_PERCENTAGE 95
#define ASIDE_SLIDING_DETECTION_ZONE_WIDTH_PERCENTAGE 6

#define DEFAULT_MINIMUM_PRESS_DURATION_TO_START_DRAGGING 0.5
#define DEFAULT_SLIDING_PAGE_WHILE_DRAGGING_WAIT_DURATION 0.8

#define CANCEL_DRAGGING_ANIMATION_DURATION 0.35

@interface KDashboard ()

@property (nonatomic, weak) UIViewController* viewControllerEmbedder;
@property (nonatomic, weak) UIView* deleteZone;
@property (nonatomic, retain) UIView* draggedCell;
@property (nonatomic, retain) UIView* bufferMovingCell;

@property (nonatomic, weak) UIPageViewController* pageViewController;
@property (nonatomic, weak) CollectionViewEmbedderViewController* currentCollectionViewEmbedder;
@property (nonatomic, retain) Class cellClass;
@property (nonatomic, retain) NSString* identifier;
@property (nonatomic, weak) UIPageControl* pageControl;
@property (nonatomic) NSInteger pageIndex;

@property (nonatomic) NSUInteger onePageElementCount;

@property (nonatomic, retain) UILongPressGestureRecognizer* longPressGesture;
@property (nonatomic, retain) UIPanGestureRecognizer* panGesture;
@property (nonatomic) NSInteger indexOfTheLastDraggedCellSource;
@property (nonatomic) BOOL movedDraggedCell;
@property (nonatomic) CGPoint memorizedDraggedCellSourceCenter;

@property (nonatomic, weak) UIView* leftSideSlidingDetectionZone;
@property (nonatomic, weak) UIView* rightSideSlidingDetectionZone;
@property (nonatomic, retain) NSTimer* slidingWhileDraggingTimer;

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
        
        _onePageElementCount = [_dataSource rowCountPerPageInDashboard:self]*[_dataSource columnCountPerPageInDashboard:self];
        
        [self.view setFrame:frame];
        
        [self layoutSubviews];
        [self setUpGestures];
        
    }
    return self;
}

-(void) setDefaultOptions{
    _indexOfTheLastDraggedCellSource = -1;
    _movedDraggedCell = NO;
    
    _showPageControl = YES;
    _showPageControlWhenOnlyOnePage = YES;
    _enableDragAndDrop = YES;
    _slidingPageWhileDraggingWaitingDuration = DEFAULT_SLIDING_PAGE_WHILE_DRAGGING_WAIT_DURATION;
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
    
    [_viewControllerEmbedder addChildViewController:self];
    [_viewControllerEmbedder.view addSubview:self.view];
    [self didMoveToParentViewController:_viewControllerEmbedder];
    
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
    aPageControl.backgroundColor = [UIColor redColor];
    aPageControl.enabled = NO;
    
    [self.view addSubview:aPageControl];
    
    return aPageControl;
}

/************************/
/* MANAGING UI ELEMENTS */
/************************/
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

#pragma mark - dequeueReusableCellWithIdentifier:forIndex:
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index{
    return [_currentCollectionViewEmbedder dequeueReusableCellWithIdentifier:identifier forIndex:index];
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
    
    if(collectionViewEmbedderViewController.pageIndex == [self pageCount]-1){
        numberOfItems = [_dataSource cellCountInDashboard:self]%_onePageElementCount;
    }else{
        numberOfItems = _onePageElementCount;
    }
    
    return numberOfItems;
}

-(UICollectionViewCell *)collectionViewEmbedderViewController:(CollectionViewEmbedderViewController*)collectionViewEmbedder cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    _currentCollectionViewEmbedder = collectionViewEmbedder;
    [self setPageIndex:_currentCollectionViewEmbedder.pageIndex];
    
    UICollectionViewCell* theCell = [_dataSource dashboard:self cellForItemAtIndex:indexPath.row+collectionViewEmbedder.pageIndex*_onePageElementCount];
    
    theCell.hidden = _pageIndex == [self pageOfThisIndex:_indexOfTheLastDraggedCellSource] && _indexOfTheLastDraggedCellSource%_onePageElementCount == indexPath.row;
    
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
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
    _longPressGesture.delegate = self;
    _longPressGesture.numberOfTouchesRequired = 1;
    _longPressGesture.minimumPressDuration = DEFAULT_MINIMUM_PRESS_DURATION_TO_START_DRAGGING;
    [self.view addGestureRecognizer:_longPressGesture];
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGesture.delegate = self;
    [self.view addGestureRecognizer:_panGesture];
}

-(void)removeGestures{
    if(_longPressGesture != nil){
        if([self.view.gestureRecognizers containsObject:_longPressGesture])[self.view removeGestureRecognizer:_longPressGesture];
        _longPressGesture = nil;
    }
}

- (void)handlePress:(UILongPressGestureRecognizer *)gesture{
    if(gesture.state == UIGestureRecognizerStateBegan){
        if(_delegate != nil){
            if([_delegate respondsToSelector:@selector(startDraggingFromDashboard:)]){
                [_delegate startDraggingFromDashboard:self];
            }
        }
        
        UICollectionView* targetedCollectionView = _currentCollectionViewEmbedder.collectionView;
        CGPoint point = [gesture locationInView:targetedCollectionView];
        NSIndexPath *indexPath = [targetedCollectionView indexPathForItemAtPoint:point];
        if (indexPath != nil) {
            _indexOfTheLastDraggedCellSource = [self getDashboardIndexWithIndexPath:indexPath];
            [self showDraggedCellWithSourceCell:[targetedCollectionView cellForItemAtIndexPath:indexPath] fromThisStartPoint:[gesture locationInView:_viewControllerEmbedder.view]];
        }
        
    }else if(gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed){
        if(!_movedDraggedCell){
            [self cancelDraggingAndGetDraggedCellBackToItsCellPosition];
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
        
        if(CGRectContainsPoint([self.view convertRect:_leftSideSlidingDetectionZone.frame toView:_viewControllerEmbedder.view], point)){
            if(_slidingWhileDraggingTimer == nil){
                _slidingWhileDraggingTimer = [NSTimer scheduledTimerWithTimeInterval:_slidingPageWhileDraggingWaitingDuration
                                                                 target:self
                                                               selector:@selector(slideToThePreviousPage)
                                                               userInfo:nil
                                                                repeats:YES];
            }
        }else if(CGRectContainsPoint([self.view convertRect:_rightSideSlidingDetectionZone.frame toView:_viewControllerEmbedder.view], point)){
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
        CGPoint droppingPoint = [gesture locationInView:_currentCollectionViewEmbedder.collectionView];
        NSIndexPath* indexPath = [_currentCollectionViewEmbedder.collectionView indexPathForItemAtPoint:droppingPoint];
        if(indexPath != nil && _indexOfTheLastDraggedCellSource != [self getDashboardIndexWithIndexPath:indexPath]){
            [self swapCellAtIndex:_indexOfTheLastDraggedCellSource withCellAtIndex:[self getDashboardIndexWithIndexPath:indexPath]];
        }else{
            [self cancelDraggingAndGetDraggedCellBackToItsCellPosition];
        }
    }
}

/*************************/
/* DRAGGED CELL MANAGING */
/*************************/
-(void) showDraggedCellWithSourceCell:(UICollectionViewCell*)cell fromThisStartPoint:(CGPoint)startPoint{
    _memorizedDraggedCellSourceCenter = cell.center;
    _draggedCell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.height)];
    for(UIView* subview in cell.subviews){
        [_draggedCell addSubview:subview];
    }
    cell.hidden = YES;
    
    _draggedCell.center = startPoint;
    [_viewControllerEmbedder.view addSubview:_draggedCell];
}

-(void) moveCellWithCellSource:(UICollectionViewCell*)cell toPreviousOrNextPage:(BOOL)previous{
    _bufferMovingCell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.height)];
    for(UIView* subview in cell.subviews){
        [_bufferMovingCell addSubview:subview];
    }
    cell.hidden = YES;
    
    _bufferMovingCell.center = [self.view convertPoint:cell.center toView:nil];
    [_viewControllerEmbedder.view addSubview:_bufferMovingCell];
    
    CGPoint cellDestinationPoint;
    if(previous){
        cellDestinationPoint = CGPointMake(_memorizedDraggedCellSourceCenter.x-self.view.frame.size.width, _memorizedDraggedCellSourceCenter.y);
    }else{
        cellDestinationPoint = CGPointMake(_memorizedDraggedCellSourceCenter.x+self.view.frame.size.width, _memorizedDraggedCellSourceCenter.y);
    }
    
    cellDestinationPoint = [self.view convertPoint:cellDestinationPoint toView:nil];
    
    [UIView animateWithDuration:CANCEL_DRAGGING_ANIMATION_DURATION
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _bufferMovingCell.center = cellDestinationPoint;
                     }
                     completion:^(BOOL finished){
                         [_bufferMovingCell removeFromSuperview];
                         _bufferMovingCell = nil;
                     }];
}

-(void) hideDraggedCellAndRestoreCellAtDashboardIndex:(NSInteger)index{
    UICollectionViewCell* lastDraggedCellSource = [self getCellAtDashboardIndex:index];
    
    if(lastDraggedCellSource != nil){
        lastDraggedCellSource.hidden = NO;
        for(UIView* subview in _draggedCell.subviews){
            [lastDraggedCellSource addSubview:subview];
        }
    }
    [_draggedCell removeFromSuperview];
    
    _indexOfTheLastDraggedCellSource = -1;
}

-(void) cancelDraggingAndGetDraggedCellBackToItsCellPosition{
    [self cancelDraggingAndMoveDraggedCellToThisDashboardIndex:_indexOfTheLastDraggedCellSource];
}

-(void) cancelDraggingAndMoveDraggedCellToThisDashboardIndex:(NSInteger)index{
    UICollectionViewCell* lastDraggedCellSource = [self getCellAtDashboardIndex:index];
    
    CGPoint originalCellPosition;
    if(lastDraggedCellSource != nil){
        originalCellPosition = lastDraggedCellSource.center;
    }else{
        if([self pageOfThisIndex:index] < _pageIndex){
            originalCellPosition = CGPointMake(_memorizedDraggedCellSourceCenter.x-self.view.frame.size.width, _memorizedDraggedCellSourceCenter.y);
        }else{
            originalCellPosition = CGPointMake(_memorizedDraggedCellSourceCenter.x+self.view.frame.size.width, _memorizedDraggedCellSourceCenter.y);
        }
    }
    
    originalCellPosition = [self.view convertPoint:originalCellPosition toView:nil];
    
    [UIView animateWithDuration:CANCEL_DRAGGING_ANIMATION_DURATION
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _draggedCell.center = originalCellPosition;
                     }
                     completion:^(BOOL finished){
                         [self hideDraggedCellAndRestoreCellAtDashboardIndex:index];
                     }];
}

/**************************/
/* SLIDING PAGES MANAGING */
/**************************/
-(void) slideToThePreviousPage{
    if(_pageIndex <= 0){
        if(_slidingWhileDraggingTimer != nil){
            [_slidingWhileDraggingTimer invalidate];
            _slidingWhileDraggingTimer = nil;
        }
    }else{
        [self pageViewController:_pageViewController switchToThisViewController:(CollectionViewEmbedderViewController*)[self pageViewController:_pageViewController viewControllerBeforeViewController:_currentCollectionViewEmbedder] withDirection:UIPageViewControllerNavigationDirectionReverse];
    }
}

-(void) slideToTheNextPage{
    if(_pageIndex >= [self pageCount]-1){
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
-(void)swapCellAtIndex:(NSInteger)sourceIndex withCellAtIndex:(NSInteger)destinationIndex{
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
        [self moveCellWithCellSource:[_currentCollectionViewEmbedder.collectionView cellForItemAtIndexPath:destinationIndexPath] toPreviousOrNextPage:(pageIndexOfSourceCell < pageIndexOfDestinationCell)];
    }
    
    [self cancelDraggingAndMoveDraggedCellToThisDashboardIndex:destinationIndex];
    
    if(_delegate != nil){
        if([_delegate respondsToSelector:@selector(dashboard:swapCellAtIndex:withCellAtIndex:)]){
            [_delegate dashboard:self swapCellAtIndex:sourceIndex withCellAtIndex:destinationIndex];
        }
    }
}

/********************/
/* GESTURE DELEGATE */
/********************/
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return (gestureRecognizer == _longPressGesture && otherGestureRecognizer == _panGesture) || (gestureRecognizer == _panGesture && otherGestureRecognizer == _longPressGesture);
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

/***************************/
/* DELETE ZONE ASSOCIATION */
/***************************/
-(void) associateADeleteZone:(UIView*)deleteZone{
    _deleteZone = deleteZone;
}

/*******************/
/* OPTIONS METHODS */
/*******************/
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
        if(_longPressGesture == nil){
            [self setUpGestures];
        }
    }else{
        [self removeGestures];
    }
}

-(void) setMinimumPressDurationToStartDragging:(CGFloat)minimumPressDurationToStartDragging{
    if(minimumPressDurationToStartDragging < 0) minimumPressDurationToStartDragging = 0;
    _minimumPressDurationToStartDragging = minimumPressDurationToStartDragging;
    if(_longPressGesture == nil){
        [self setUpGestures];
    }
    _longPressGesture.minimumPressDuration = minimumPressDurationToStartDragging;
}

-(void) setSlidingPageWhileDraggingWaitingDuration:(CGFloat)slidingPageWhileDraggingWaitingDuration{
    _slidingPageWhileDraggingWaitingDuration = slidingPageWhileDraggingWaitingDuration;
}

@end
