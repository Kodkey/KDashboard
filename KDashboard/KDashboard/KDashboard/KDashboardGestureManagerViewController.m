//
//  KDashboardGestureManagerViewController.m
//  KDashboard
//
//  Created by KODKEY on 23/10/2015.
//  Copyright (c) 2015 KODKEY. All rights reserved.
//

#import "KDashboardGestureManagerViewController.h"
#import "KDashboard.h"

#define DEFAULT_MINIMUM_PRESS_DURATION_TO_START_DRAGGING 0.5

@interface KDashboardGestureManagerViewController ()

@property (nonatomic, retain) UILongPressGestureRecognizer* longPressGesture;
@property (nonatomic, retain) UIPanGestureRecognizer* panGesture;

@property (nonatomic, retain) NSMutableArray* dashboards;

@property (nonatomic, weak) KDashboard* sourceDashboard;
@property (nonatomic, weak) KDashboard* lastTargetedDashboard;

@end

@implementation KDashboardGestureManagerViewController

+(id) sharedManager{
    static KDashboardGestureManagerViewController *sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

-(id) init{
    if(self = [super init]){
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        [self.view setFrame:screenRect];
        
        [self setUpGestures];
        
        _dashboards = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) registerDashboardForDragAndDrop:(KDashboard*)dashboard{
    if(![_dashboards containsObject:dashboard]){
        [_dashboards addObject:dashboard];
        
        if(_dashboards.count == 1){
            [self add:self toParentViewController:dashboard.viewControllerEmbedder];
            [dashboard.viewControllerEmbedder.view sendSubviewToBack:self.view];
        }
        
        [self add:dashboard toParentViewController:self];
    }
}

-(void) unregisterDashboardForDragAndDrop:(KDashboard*)dashboard{
    if([_dashboards containsObject:dashboard]){
        [_dashboards removeObject:dashboard];
    }
}

-(void) dissociateADashboard:(KDashboard*)dashboard{
    [self removeViewControllerFromParentViewController:dashboard];
}

-(void) add:(UIViewController*)viewController toParentViewController:(UIViewController*)parentViewController{
    if(![parentViewController.view.subviews containsObject:viewController.view]){
        [parentViewController addChildViewController:viewController];
        [parentViewController.view addSubview:viewController.view];
        [viewController didMoveToParentViewController:parentViewController];
    }
}

-(void) removeViewControllerFromParentViewController:(UIViewController*)viewController{
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

-(void) setUpGestures{
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
    _longPressGesture.delegate = self;
    _longPressGesture.numberOfTouchesRequired = 1;
    _longPressGesture.minimumPressDuration = DEFAULT_MINIMUM_PRESS_DURATION_TO_START_DRAGGING;
    [self.view addGestureRecognizer:_longPressGesture];
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGesture.delegate = self;
    [self.view addGestureRecognizer:_panGesture];
}

-(void) setMinimumPressDurationToStartDragging:(CGFloat)minimumPressDuration{
    _longPressGesture.minimumPressDuration = minimumPressDuration;
}

-(void) handlePress:(UILongPressGestureRecognizer*)gesture{
    KDashboard* targetedDashboard = [[self dashboardsUnderPoint:[gesture locationInView:self.view]] lastObject];
    
    if(targetedDashboard != nil){
        if(gesture.state == UIGestureRecognizerStateBegan){
            _sourceDashboard = targetedDashboard;
        }
        
        if(targetedDashboard.enableDragAndDrop)[targetedDashboard handlePress:gesture];
    }
}

-(void) handlePan:(UIPanGestureRecognizer*)gesture{
    KDashboard* targetedDashboard = [[self dashboardsUnderPoint:[gesture locationInView:self.view]] lastObject];
    
    if(targetedDashboard != _lastTargetedDashboard){
        [_lastTargetedDashboard cancelCanCreateAGroupTimer];
    }
    _lastTargetedDashboard = targetedDashboard;
    
    if((gesture.state == UIGestureRecognizerStateRecognized || gesture.state == UIGestureRecognizerStateChanged) && targetedDashboard != nil && targetedDashboard != _sourceDashboard){
        targetedDashboard.draggedCell = _sourceDashboard.draggedCell;
        targetedDashboard.insideDashboard = YES;
        targetedDashboard.movedDraggedCell = YES;
        
        targetedDashboard.sourceDashboard = _sourceDashboard;
    }else{
        targetedDashboard = _sourceDashboard;
        targetedDashboard.sourceDashboard = nil;
    }
    
    if(targetedDashboard != nil && targetedDashboard.enableDragAndDrop)[targetedDashboard handlePan:gesture];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return (gestureRecognizer == _longPressGesture && otherGestureRecognizer == _panGesture) || (gestureRecognizer == _panGesture && otherGestureRecognizer == _longPressGesture);
}

-(NSMutableArray*)dashboardsUnderPoint:(CGPoint)point{
    NSMutableArray* dashboardsUnderPoint = [[NSMutableArray alloc] init];
    
    for(KDashboard* aDashboard in _dashboards){
        if(CGRectContainsPoint(aDashboard.view.frame, point)){
            [dashboardsUnderPoint addObject:aDashboard];
        }
    }
    
    return dashboardsUnderPoint;
}

-(BOOL)knowsThisDashboard:(KDashboard*)dashboard{
    return [_dashboards containsObject:dashboard];
}

-(BOOL)isStillThereAVisibleDashboard{
    for(KDashboard* aDashboard in _dashboards){
        if(aDashboard.view.window) return YES;
    }
    return NO;
}

@end
