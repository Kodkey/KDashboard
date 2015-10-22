//
//  CollectionViewEmbedderViewController.m
//  KDashboard
//
//  Created by COURELJordan on 13/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import "CollectionViewEmbedderViewController.h"

#define DEFAULT_MAX_COLUMN_ROW_COUNT 3

@interface CollectionViewEmbedderViewController ()

@property (nonatomic) CGRect theFrame;

@property (nonatomic, weak) Class cellClass;
@property (nonatomic, weak) NSString* identifier;

@end

@implementation CollectionViewEmbedderViewController

#pragma mark - initialisation
- (id) initWithFrame:(CGRect)frame andDataSource:(id<CollectionViewEmbedderViewControllerDataSource>)dataSource andDelegate:(id<CollectionViewEmbedderViewControllerDelegate>)delegate andCellClass:(Class)cellClass andReuseIdentifier:(NSString*)identifier{
    if(self = [super init]){
        
        _dataSource = dataSource;
        _delegate = delegate;
        _cellClass = cellClass;
        _identifier = identifier;
        
        _theFrame = frame;
        self.view.frame = frame;
    }
    return self;
}

-(void) viewDidLoad{
    [super viewDidLoad];
    
    _collectionView = [self createCollectionViewWithFrame:_theFrame];
}

#pragma mark - CollectionView configuration
-(UICollectionView*) createCollectionViewWithFrame:(CGRect)frame{
    
    UICollectionViewFlowLayout* collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    [collectionViewFlowLayout setItemSize:CGSizeMake(frame.size.width/[_dataSource maxColumnCount], frame.size.height/[_dataSource maxRowCount])];
    [collectionViewFlowLayout setMinimumInteritemSpacing:0];
    [collectionViewFlowLayout setMinimumLineSpacing:0];
    
    UICollectionView* aCollectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:collectionViewFlowLayout];
    [self.view addSubview:aCollectionView];
    aCollectionView.backgroundColor = [UIColor clearColor];
    aCollectionView.showsHorizontalScrollIndicator = NO;
    aCollectionView.showsVerticalScrollIndicator = NO;
    aCollectionView.bounces = NO;
    
    [aCollectionView registerClass:_cellClass forCellWithReuseIdentifier:_identifier];
    
    aCollectionView.delegate = self;
    aCollectionView.dataSource = self;
    
    return aCollectionView;
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index-_pageIndex*([_dataSource maxRowCount]*[_dataSource maxColumnCount]) inSection:0];
    return [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [_dataSource numberOfItemsInThisCollectionViewEmbedderViewController:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    return [_dataSource collectionViewEmbedderViewController:self cellForItemAtIndexPath:indexPath];
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if(_delegate != nil){
        if([_delegate respondsToSelector:@selector(collectionViewEmbedder:didSelectItemAtIndexPath:)]){
            [_delegate collectionViewEmbedder:self didSelectItemAtIndexPath:indexPath];
        }
    }
}

#pragma mark - didReceiveMemoryWarning
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
