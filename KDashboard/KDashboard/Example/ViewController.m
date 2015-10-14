//
//  ViewController.m
//  KDashboard
//
//  Created by COURELJordan on 13/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import "ViewController.h"

#import "CollectionViewCell.h"

#define ROW_COUNT 7
#define COLUMN_COUNT 8
#define CELL_COUNT 122

#define CELL_NAME @"Cell"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customize];
}

- (void) customize{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    self.view.backgroundColor = [UIColor yellowColor];
    
    KDashboard* dashboard = [[KDashboard alloc] initWithFrame:CGRectMake(0, screenRect.size.height*10/100, screenRect.size.width, screenRect.size.height*80/100) andDataSource:self andDelegate:self andCellClass:[CollectionViewCell class] andReuseIdentifier:CELL_NAME];
    dashboard.view.backgroundColor = [UIColor cyanColor];
    
    [self addChildViewController:dashboard];
    [self.view addSubview:dashboard.view];
    [dashboard didMoveToParentViewController:self];
}

-(NSUInteger)rowCountPerPageInDashboard:(KDashboard*)dashboard{
    return ROW_COUNT;
}

-(NSUInteger)columnCountPerPageInDashboard:(KDashboard*)dashboard{
    return COLUMN_COUNT;
}

-(NSUInteger)cellCountInDashboard:(KDashboard*)dashboard{
    return CELL_COUNT;
}

-(CollectionViewCell*)dashboard:(KDashboard*)dashboard cellForItemAtIndex:(NSUInteger)index{
    CollectionViewCell* cell = nil;

    cell = (CollectionViewCell*) [dashboard dequeueReusableCellWithIdentifier:CELL_NAME forIndex:index];

    [cell customizeWithImage:[UIImage imageNamed:@"imagecell.png"] andText:[NSString stringWithFormat:@"cell%lu",(unsigned long)index]];
    
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
