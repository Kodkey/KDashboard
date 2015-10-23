//
//  CollectionViewCell.h
//  KDashboard
//
//  Created by KODKEY on 14/10/2015.
//  Copyright (c) 2015 KODKEY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionViewCell : UICollectionViewCell

@property (nonatomic) BOOL isAGroup;

-(void) customizeWithImage:(UIImage*)image andText:(NSString*)text;
-(void) customizeGroupWithDotCount:(NSInteger)dotCount andText:(NSString*)text;
-(void) toggleGroupView;

-(void) setDotCount:(NSInteger)dotCount;
-(void) setRowDotCount:(NSInteger)rowDotCount andColumnDotCount:(NSInteger)columntDotCount;

@end
