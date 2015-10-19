//
//  ViewController.m
//  KDashboard
//
//  Created by COURELJordan on 13/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import "ViewController.h"

#import "CollectionViewCell.h"

#define ROW_COUNT 4
#define COLUMN_COUNT 4
#define CELL_COUNT 100

#define CELL_NAME @"Cell"

@interface ViewController ()

@property (nonatomic, retain) NSMutableArray* dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createData];
    [self customize];
}

-(void) createData{
    _dataArray = [[NSMutableArray alloc] init];
    for(int i=0;i<CELL_COUNT;i++){
        [_dataArray addObject:[NSNumber numberWithInt:i]];
    }
}

- (void) customize{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    self.view.backgroundColor = [UIColor yellowColor];
    
    KDashboard* dashboard = [[KDashboard alloc] initWithFrame:CGRectMake(0, screenRect.size.height*12.5/100, screenRect.size.width, screenRect.size.height*75/100) andDataSource:self andDelegate:self andCellClass:[CollectionViewCell class] andReuseIdentifier:CELL_NAME andAssociateToThisViewController:self];
    dashboard.view.backgroundColor = [UIColor cyanColor];
    
    UIView* delZone = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height*10/100)];
    delZone.backgroundColor = [UIColor magentaColor];
    [self.view addSubview:delZone];
    
    [dashboard associateADeleteZone:delZone];
}

#pragma mark - DASHBOARD DATA SOURCE METHODS
-(NSUInteger)rowCountPerPageInDashboard:(KDashboard*)dashboard{
    return ROW_COUNT;
}

-(NSUInteger)columnCountPerPageInDashboard:(KDashboard*)dashboard{
    return COLUMN_COUNT;
}

-(NSUInteger)cellCountInDashboard:(KDashboard*)dashboard{
    return [_dataArray count];
}

-(CollectionViewCell*)dashboard:(KDashboard*)dashboard cellForItemAtIndex:(NSUInteger)index{
    CollectionViewCell* cell = nil;

    cell = (CollectionViewCell*) [dashboard dequeueReusableCellWithIdentifier:CELL_NAME forIndex:index];

    [cell customizeWithImage:[UIImage imageNamed:@"imagecell.png"] andText:[NSString stringWithFormat:@"cell%d",[[_dataArray objectAtIndex:index] intValue]]];
    
    return cell;
}

#pragma mark - DASHBOARD DELEGATE METHODS
-(void)dashboard:(KDashboard*)dashboard swapCellAtIndex:(NSInteger)sourceIndex withCellAtIndex:(NSUInteger)destinationIndex{
    [_dataArray exchangeObjectAtIndex:sourceIndex withObjectAtIndex:destinationIndex];
}

-(void)dashboard:(KDashboard*)dashboard insertCellFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex{
    id removedObject = [_dataArray objectAtIndex:sourceIndex];
    [_dataArray removeObjectAtIndex:sourceIndex];
    [_dataArray insertObject:removedObject atIndex:destinationIndex];
}

-(void)dashboard:(KDashboard*)dashboard deleteCellAtIndex:(NSInteger)index{
    [_dataArray removeObjectAtIndex:index];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
