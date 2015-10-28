//
//  ViewController.m
//  KDashboard
//
//  Created by KODKEY on 13/10/2015.
//  Copyright (c) 2015 KODKEY. All rights reserved.
//

#import "ViewController.h"

#import "CollectionViewCell.h"

#define ROW_COUNT 4
#define COLUMN_COUNT 4
#define CELL_COUNT 100

#define CELL_NAME @"Cell"

@interface ViewController ()

@property (nonatomic, retain) KDashboard* mainDashboard;
@property (nonatomic, retain) KDashboard* groupDashboard;
@property (nonatomic, retain) UILabel* deleteZone;

@property (nonatomic, retain) NSMutableArray* dataArray;

@property (nonatomic) NSInteger lastHollowingGroupCellIndex;
@property (nonatomic) NSInteger indexOfTheOpenedGroup;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _lastHollowingGroupCellIndex = -1;
    _indexOfTheOpenedGroup = -1;
    
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
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _mainDashboard = [[KDashboard alloc] initWithFrame:CGRectMake(0, screenRect.size.height*12.5/100, screenRect.size.width, screenRect.size.height*75/100) andDataSource:self andDelegate:self andCellClass:[CollectionViewCell class] andReuseIdentifier:CELL_NAME andAssociateToThisViewController:self];
    [_mainDashboard display];
    _mainDashboard.view.backgroundColor = [UIColor grayColor];
    
    _deleteZone = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height*10/100)];
    [_deleteZone setText:@"DELETE ZONE"];
    _deleteZone.textAlignment = NSTextAlignmentCenter;
    _deleteZone.lineBreakMode = NSLineBreakByWordWrapping;
    _deleteZone.numberOfLines = 0;
    _deleteZone.textColor = [UIColor whiteColor];
    _deleteZone.font = [_deleteZone.font fontWithSize:screenRect.size.height*3/100];
    _deleteZone.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_deleteZone];
    
    [_mainDashboard associateADeleteZone:_deleteZone];
}

#pragma mark - GROUP MANAGING
-(void) createAndShowGroupDashboardWithGroupIndex:(NSInteger)groupIndex{
    _mainDashboard.enableDragAndDrop = NO;
    _mainDashboard.view.userInteractionEnabled = NO;
    
    _indexOfTheOpenedGroup = groupIndex;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    _groupDashboard = [[KDashboard alloc] initWithFrame:CGRectMake(screenRect.size.width*5/100, screenRect.size.height*15/100, screenRect.size.width*90/100, screenRect.size.height*70/100) andDataSource:self andDelegate:self andCellClass:[CollectionViewCell class] andReuseIdentifier:CELL_NAME andAssociateToThisViewController:self];
    _groupDashboard.showPageControl = NO;
    _groupDashboard.enableGroupCreation = NO;
    _groupDashboard.bounces = NO;
    [_groupDashboard display];
    
    _groupDashboard.view.backgroundColor = [UIColor lightGrayColor];
    _groupDashboard.view.layer.borderColor = [UIColor blackColor].CGColor;
    _groupDashboard.view.layer.borderWidth = _groupDashboard.view.frame.size.width*0.1/100;
    
    UILabel* indicationLabel = [[UILabel alloc] initWithFrame:_groupDashboard.view.bounds];
    [indicationLabel setText:@"Tap on background to dismiss"];
    indicationLabel.textAlignment = NSTextAlignmentCenter;
    indicationLabel.lineBreakMode = NSLineBreakByWordWrapping;
    indicationLabel.numberOfLines = 0;
    indicationLabel.textColor = [UIColor whiteColor];
    indicationLabel.font = [indicationLabel.font fontWithSize:screenRect.size.height*3/100];
    [_groupDashboard.view addSubview:indicationLabel];
    [_groupDashboard.view sendSubviewToBack:indicationLabel];
    
    [_groupDashboard associateADeleteZone:_deleteZone];
    
    [_groupDashboard.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeGroupNow)]];
    
}

-(void) closeGroupNow{
    [self closeGroupDashboard];
    
    _indexOfTheOpenedGroup = -1;
}

-(void) closeGroupDashboard{
    if(_groupDashboard != nil){
        [_groupDashboard willMoveToParentViewController:nil];
        [_groupDashboard.view removeFromSuperview];
        [_groupDashboard removeFromParentViewController];
    }
    
    _mainDashboard.enableDragAndDrop = YES;
    _mainDashboard.view.userInteractionEnabled = YES;
}

-(NSMutableArray*)getEffectiveDataArrayWithDashboard:(KDashboard*)dashboard{
    NSMutableArray* effectiveDataArray;
    if(dashboard == _mainDashboard){
        effectiveDataArray = _dataArray;
    }else{
        effectiveDataArray = (NSMutableArray*)[_dataArray objectAtIndex:_indexOfTheOpenedGroup];
    }
    
    return effectiveDataArray;
}

#pragma mark - DASHBOARD DATA SOURCE METHODS
-(NSUInteger)rowCountPerPageInDashboard:(KDashboard*)dashboard{
    if(dashboard == _mainDashboard){
        return ROW_COUNT;
    }else if(dashboard == _groupDashboard){
        return 0;
    }
    return ROW_COUNT;
}

-(NSUInteger)columnCountPerPageInDashboard:(KDashboard*)dashboard{
    return COLUMN_COUNT;
}

-(NSUInteger)cellCountInDashboard:(KDashboard*)dashboard{
    if(dashboard == _mainDashboard){
        return _dataArray.count;
    }else if(dashboard == _groupDashboard){
        id data = [_dataArray objectAtIndex:_indexOfTheOpenedGroup];
        if([data isKindOfClass:[NSArray class]]){
            NSArray* groupDataArray = (NSArray*)data;
            return [groupDataArray count];
        }
    }
    
    return 0;
}

-(CollectionViewCell*)dashboard:(KDashboard*)dashboard cellForItemAtIndex:(NSUInteger)index{
    CollectionViewCell* cell = nil;

    cell = (CollectionViewCell*) [dashboard dequeueReusableCellWithIdentifier:CELL_NAME forIndex:index];
    
    NSMutableArray* effectiveDataArray = [self getEffectiveDataArrayWithDashboard:dashboard];

    id data = [effectiveDataArray objectAtIndex:index];
    if([data isKindOfClass:[NSArray class]]){
        NSArray* groupDataArray = (NSArray*)data;
        [cell customizeGroupWithDotCount:[groupDataArray count] andText:[NSString stringWithFormat:@"Group"]];
    }else if([data isKindOfClass:[NSNumber class]]){
        NSInteger value = [(NSNumber*)data intValue];
        [cell customizeWithImage:[UIImage imageNamed:@"imagecell.png"] andText:[NSString stringWithFormat:@"cell%d",value]];
    }
    
    return cell;
}

#pragma mark - DASHBOARD DELEGATE METHODS
-(BOOL)dashboard:(KDashboard*)dashboard swapCellAtIndex:(NSInteger)sourceIndex withCellAtIndex:(NSUInteger)destinationIndex{
    NSMutableArray* effectiveDataArray = [self getEffectiveDataArrayWithDashboard:dashboard];
    [effectiveDataArray exchangeObjectAtIndex:sourceIndex withObjectAtIndex:destinationIndex];
    
    return YES;
}

-(BOOL)dashboard:(KDashboard*)dashboard swapCellAtIndex:(NSInteger)sourceIndex withCellAtIndex:(NSUInteger)destinationIndex fromAnotherDashboard:(KDashboard*)anotherDashboard{
    
    if(destinationIndex == _indexOfTheOpenedGroup) return NO;
    
    NSMutableArray* groupDataArray = [[self getEffectiveDataArrayWithDashboard:dashboard] objectAtIndex:_indexOfTheOpenedGroup];
    
    NSMutableArray* sourceDataArray = anotherDashboard == _groupDashboard ? groupDataArray : _dataArray;
    NSMutableArray* destinationDataArray = anotherDashboard == _groupDashboard ? _dataArray : groupDataArray;
    
    id buffer = [sourceDataArray objectAtIndex:sourceIndex];
    [sourceDataArray replaceObjectAtIndex:sourceIndex withObject:[destinationDataArray objectAtIndex:destinationIndex]];
    [destinationDataArray replaceObjectAtIndex:destinationIndex withObject:buffer];
    
    _indexOfTheOpenedGroup = -1;
    
    return YES;
}

-(BOOL)dashboard:(KDashboard*)dashboard insertCellFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex{
    NSMutableArray* effectiveDataArray = [self getEffectiveDataArrayWithDashboard:dashboard];
    id removedObject = [effectiveDataArray objectAtIndex:sourceIndex];
    [effectiveDataArray removeObjectAtIndex:sourceIndex];
    [effectiveDataArray insertObject:removedObject atIndex:destinationIndex];
    
    return YES;
}

-(BOOL)dashboard:(KDashboard *)dashboard insertCellFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex fromAnotherDashboard:(KDashboard *)anotherDashboard{
    
    NSMutableArray* groupDataArray = [[self getEffectiveDataArrayWithDashboard:dashboard] objectAtIndex:_indexOfTheOpenedGroup];
    
    NSMutableArray* sourceDataArray = anotherDashboard == _groupDashboard ? groupDataArray : _dataArray;
    NSMutableArray* destinationDataArray = anotherDashboard == _groupDashboard ? _dataArray : groupDataArray;
    
    [destinationDataArray insertObject:[sourceDataArray objectAtIndex:sourceIndex] atIndex:destinationIndex];
    [sourceDataArray removeObjectAtIndex:sourceIndex];
    
    return YES;
}

-(BOOL)dashboard:(KDashboard*)dashboard deleteCellAtIndex:(NSInteger)index{
    NSMutableArray* effectiveDataArray = [self getEffectiveDataArrayWithDashboard:dashboard];
    [effectiveDataArray removeObjectAtIndex:index];
    
    if(((CollectionViewCell*)[_mainDashboard cellAtDashboardIndex:_indexOfTheOpenedGroup]).isAGroup){
        [_mainDashboard reloadData];
    }
    
    return YES;
}

-(void)dashboard:(KDashboard*)dashboard userTappedOnACellAtThisIndex:(NSInteger)index{
    
    if(((CollectionViewCell*)[dashboard cellAtDashboardIndex:index]).isAGroup){
        [self createAndShowGroupDashboardWithGroupIndex:index];
    }
}

-(void)dashboard:(KDashboard *)dashboard canCreateGroupAtIndex:(NSInteger)index withSourceIndex:(NSInteger)sourceIndex{
    if(((CollectionViewCell*)[dashboard cellAtDashboardIndex:sourceIndex]).isAGroup || _indexOfTheOpenedGroup == index){
        _lastHollowingGroupCellIndex = -1;
        return;
    }
    
    _lastHollowingGroupCellIndex = index;
    CollectionViewCell* lastHollowingGroupCell = (CollectionViewCell*)[dashboard cellAtDashboardIndex:index];
    
    if(lastHollowingGroupCell.isAGroup){
        id data = [_dataArray objectAtIndex:index];
        if([data isKindOfClass:[NSArray class]]){
            NSArray* groupDataArray = (NSArray*)data;
            [lastHollowingGroupCell setDotCount:[groupDataArray count]+1];
        }
    }else{
        [lastHollowingGroupCell setDotCount:2];
        [lastHollowingGroupCell toggleGroupView];
    }
}

-(void)dismissGroupCreationPossibilityFromDashboard:(KDashboard*)dashboard{
    
    CollectionViewCell* lastHollowingGroupCell = (CollectionViewCell*)[dashboard cellAtDashboardIndex:_lastHollowingGroupCellIndex];
    
    if(lastHollowingGroupCell.isAGroup){
        id data = [_dataArray objectAtIndex:_lastHollowingGroupCellIndex];
        if([data isKindOfClass:[NSArray class]]){
            NSArray* groupDataArray = (NSArray*)data;
            [lastHollowingGroupCell setDotCount:[groupDataArray count]];
        }
    }else{
        [lastHollowingGroupCell toggleGroupView];
    }
}

-(void)dashboard:(KDashboard*)dashboard addGroupAtIndex:(NSInteger)index withCellAtIndex:(NSInteger)sourceIndex{
    if(((CollectionViewCell*)[dashboard cellAtDashboardIndex:sourceIndex]).isAGroup){
        return;
    }
    
    id data = [_dataArray objectAtIndex:index];
    /*
    if([data isKindOfClass:[NSArray class]]){
        NSMutableArray* groupDataArray = [NSMutableArray arrayWithArray:(NSArray*)data];
        [groupDataArray addObject:[_dataArray objectAtIndex:sourceIndex]];
        
        [_dataArray replaceObjectAtIndex:index withObject:groupDataArray];
    }else if([data isKindOfClass:[NSNumber class]]){
        [_dataArray insertObject:[NSMutableArray arrayWithObjects:[_dataArray objectAtIndex:sourceIndex],[_dataArray objectAtIndex:index], nil] atIndex:index];
    }*/
    
    /*
    ^^^^^^^^^^
    KEEP SUBELEMENTS IN THE DASHBOARD AND COPY THEM TO THE GROUP
    
    OR
    
    DELETE ELEMENTS FROM DASHBOARD AND ADD THEM TO THE GROUP
    vvvvvvvvvv
    */
    
    if([data isKindOfClass:[NSArray class]]){
        NSMutableArray* groupDataArray = [NSMutableArray arrayWithArray:(NSArray*)data];
        [groupDataArray addObject:[_dataArray objectAtIndex:sourceIndex]];
        [_dataArray replaceObjectAtIndex:index withObject:groupDataArray];
    }else if([data isKindOfClass:[NSNumber class]]){
        [_dataArray replaceObjectAtIndex:index withObject:[NSMutableArray arrayWithObjects:[_dataArray objectAtIndex:sourceIndex],[_dataArray objectAtIndex:index], nil]];
        
    }
    [_dataArray removeObjectAtIndex:sourceIndex];
}

-(void)dashboard:(KDashboard*)dashboard addGroupAtIndex:(NSInteger)index withCellAtIndex:(NSInteger)sourceIndex fromAnotherDashboard:(KDashboard*)anotherDashboard{
    
    NSMutableArray* groupDataArray = [[self getEffectiveDataArrayWithDashboard:dashboard] objectAtIndex:_indexOfTheOpenedGroup];
    
    NSMutableArray* sourceDataArray = anotherDashboard == _groupDashboard ? groupDataArray : _dataArray;
    NSMutableArray* destinationDataArray = anotherDashboard == _groupDashboard ? _dataArray : groupDataArray;
    /*
    if([[destinationDataArray objectAtIndex:index] isKindOfClass:[NSArray class]]){
        NSMutableArray* destinationGroupDataArray = (NSMutableArray*)[destinationDataArray objectAtIndex:index];
        [destinationGroupDataArray addObject:[sourceDataArray objectAtIndex:sourceIndex]];
    }else{
        [destinationDataArray insertObject:[NSMutableArray arrayWithObjects:[sourceDataArray objectAtIndex:sourceIndex],[destinationDataArray objectAtIndex:index], nil] atIndex:index];
    }*/
    
    /*
    ^^^^^^^^^^
    KEEP SUBELEMENTS IN THE DASHBOARD AND COPY THEM TO THE GROUP
    
    OR
    
    DELETE ELEMENTS FROM DASHBOARD AND ADD THEM TO THE GROUP
    vvvvvvvvvv
    */
    
    if([[destinationDataArray objectAtIndex:index] isKindOfClass:[NSArray class]]){
        NSMutableArray* destinationGroupDataArray = (NSMutableArray*)[destinationDataArray objectAtIndex:index];
        [destinationGroupDataArray addObject:[sourceDataArray objectAtIndex:sourceIndex]];
    }else{
        [destinationDataArray replaceObjectAtIndex:index withObject:[NSMutableArray arrayWithObjects:[sourceDataArray objectAtIndex:sourceIndex],[destinationDataArray objectAtIndex:index], nil]];
    }
    [sourceDataArray removeObjectAtIndex:sourceIndex];
}

-(void)dashboard:(KDashboard *)dashboard userDraggedCellOutsideDashboard:(UIView *)draggedCell{
    if(dashboard == _groupDashboard){
        [self closeGroupDashboard];
    }
}

@end
