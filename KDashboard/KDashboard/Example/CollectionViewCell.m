//
//  CollectionViewCell.m
//  KDashboard
//
//  Created by COURELJordan on 14/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import "CollectionViewCell.h"

@implementation CollectionViewCell

-(id) initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        [self customInit];
    }
    return self;
}

-(void) customInit{
    //self.backgroundColor = [UIColor grayColor];
    
    CGFloat imageViewSquareSize = self.frame.size.height*80/100;
    
    _cellImageView = [self createImageViewWithFrame:CGRectMake((self.frame.size.width-imageViewSquareSize)/2, 0, imageViewSquareSize, imageViewSquareSize)];
    
    _cellLabel = [self createLabelWithFrame:CGRectMake(0, imageViewSquareSize, self.frame.size.width, self.frame.size.height-imageViewSquareSize)];
}

-(UIImageView*) createImageViewWithFrame:(CGRect)frame{
    UIImageView* anImageView = [[UIImageView alloc] initWithFrame:frame];
    
    [self addSubview:anImageView];
    
    return anImageView;
}

-(UILabel*) createLabelWithFrame:(CGRect)frame{
    UILabel* aLabel = [[UILabel alloc] initWithFrame:frame];
    aLabel.textAlignment = NSTextAlignmentCenter;
    aLabel.font = [aLabel.font fontWithSize:frame.size.height*80/100];
    
    [self addSubview:aLabel];
    
    return aLabel;
}

-(void) customizeWithImage:(UIImage*)image andText:(NSString*)text{
    _cellImageView.image = image;
    _cellLabel.text = text;
}

@end
