//
//  CollectionViewCell.m
//  KDashboard
//
//  Created by COURELJordan on 14/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import "CollectionViewCell.h"

#import "GroupView.h"

#define TOGGLE_GROUP_HOLLOW_ANIMATION_DURATION 0.15

@interface CollectionViewCell ()

@property (nonatomic, weak) UIImageView* cellImageView;
@property (nonatomic, weak) UILabel* cellLabel;
@property (nonatomic) GroupView* groupView;

@end

@implementation CollectionViewCell

-(id) initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        [self customInit];
    }
    return self;
}

-(void) customInit{
    CGFloat imageViewSquareSize = MIN(self.frame.size.height*80/100,self.frame.size.width*95/100);
    
    _cellImageView = [self createImageViewWithFrame:CGRectMake((self.frame.size.width-imageViewSquareSize)/2, 0, imageViewSquareSize, imageViewSquareSize)];
    
    _cellLabel = [self createLabelWithFrame:CGRectMake(0, imageViewSquareSize, self.frame.size.width, self.frame.size.height-imageViewSquareSize)];
    
    _groupView = [[GroupView alloc] initWithFrame:_cellImageView.frame];
    _groupView.alpha = 0;
    [self addSubview:_groupView];
}

-(UIImageView*) createImageViewWithFrame:(CGRect)frame{
    UIImageView* anImageView = [[UIImageView alloc] initWithFrame:frame];
    
    [self addSubview:anImageView];
    
    return anImageView;
}

-(UILabel*) createLabelWithFrame:(CGRect)frame{
    UILabel* aLabel = [[UILabel alloc] initWithFrame:frame];
    aLabel.textAlignment = NSTextAlignmentCenter;
    aLabel.font = [aLabel.font fontWithSize:self.frame.size.height*15/100];
    
    [self addSubview:aLabel];
    
    return aLabel;
}

-(void) customizeWithImage:(UIImage*)image andText:(NSString*)text{
    _cellImageView.image = image;
    _cellLabel.text = text;
    
    _isAGroup = NO;
    _cellImageView.alpha = 1;
    _groupView.alpha = 0;
}

-(void) customizeGroupWithDotCount:(NSInteger)dotCount andText:(NSString*)text{
    [_groupView setDotCount:dotCount];
    _cellLabel.text = text;
    
    _isAGroup = YES;
    _cellImageView.alpha = 0;
    _groupView.alpha = 1;
}

-(void) toggleGroupView{
    [UIView animateWithDuration:TOGGLE_GROUP_HOLLOW_ANIMATION_DURATION
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _cellImageView.alpha = -(_cellImageView.alpha-1);
                         _cellLabel.alpha = -(_cellLabel.alpha-1);
                         _groupView.alpha = -(_groupView.alpha-1);
                     }
                     completion:^(BOOL finished){
                         
                     }];
}

-(void) setDotCount:(NSInteger)dotCount{
    [_groupView setDotCount:dotCount];
}

-(void) setRowDotCount:(NSInteger)rowDotCount andColumnDotCount:(NSInteger)columntDotCount{
    [_groupView setRowDotCount:rowDotCount andColumnDotCount:columntDotCount];
}

@end
