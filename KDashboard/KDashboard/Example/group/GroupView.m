//
//  GroupView.m
//  KDashboard
//
//  Created by KODKEY on 21/10/2015.
//  Copyright (c) 2015 KODKEY. All rights reserved.
//

#import "GroupView.h"
#import "DotView.h"

#define DEFAULT_DOT_COUNT 2
#define DEFAULT_ROW_DOT_COUNT 4
#define DEFAULT_COLUMN_DOT_COUNT 4

@interface GroupView ()

@property (nonatomic) NSInteger dotCount;

@property (nonatomic) NSInteger rowDotCount;
@property (nonatomic) NSInteger columnDotCount;

@end

@implementation GroupView

-(id) initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        _dotCount = DEFAULT_DOT_COUNT;
        _rowDotCount = DEFAULT_ROW_DOT_COUNT;
        _columnDotCount = DEFAULT_COLUMN_DOT_COUNT;
        
        [self customize];
        [self setDotCount:_dotCount];
    }
    return self;
}

-(void) customize{
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.borderWidth = self.frame.size.width*5/100;
    self.layer.cornerRadius = self.frame.size.width*10/100;
}

-(void) setDotCount:(NSInteger)dotCount{
    _dotCount = dotCount;
    
    for(UIView* subview in self.subviews){
        [subview removeFromSuperview];
    }
    
    NSInteger displayedDotCount = MIN(_rowDotCount*_columnDotCount, _dotCount);
    CGFloat dotSquareSize = MAX((self.frame.size.width*25/100)/MAX(_rowDotCount, _columnDotCount),self.frame.size.width*3/100);
    CGFloat marginX = dotSquareSize/2;
    CGFloat marginY = dotSquareSize/2;
    
    CGFloat positionX, positionY;
    for(int i=0;i<displayedDotCount;i++){
        positionX = marginX+((((i%_columnDotCount)*2+1)*(self.frame.size.width-2*marginX)/_columnDotCount)-dotSquareSize)/2;
        positionY = marginY+((((i/_columnDotCount)*2+1)*(self.frame.size.height-2*marginY)/_rowDotCount)-dotSquareSize)/2;
        [self addSubview:[[DotView alloc] initWithFrame:CGRectMake(positionX, positionY, dotSquareSize, dotSquareSize)]];
    }
}

-(void) setRowDotCount:(NSInteger)rowDotCount andColumnDotCount:(NSInteger)columntDotCount{
    _rowDotCount = rowDotCount;
    _columnDotCount = columntDotCount;
    [self setDotCount:_dotCount];
}

@end
