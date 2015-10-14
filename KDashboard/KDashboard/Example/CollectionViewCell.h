//
//  CollectionViewCell.h
//  KDashboard
//
//  Created by COURELJordan on 14/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) UIImageView* cellImageView;
@property (nonatomic, weak) UILabel* cellLabel;

-(void) customizeWithImage:(UIImage*)image andText:(NSString*)text;

@end
