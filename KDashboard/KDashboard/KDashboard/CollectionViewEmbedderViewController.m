//
//  CollectionViewEmbedderViewController.m
//  KDashboard
//
//  Created by COURELJordan on 13/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import "CollectionViewEmbedderViewController.h"

@interface CollectionViewEmbedderViewController ()

@property (nonatomic, weak) UICollectionView* collectionView;

@end

@implementation CollectionViewEmbedderViewController

#pragma mark - initialisation
- (id) init{
    if(self = [super init]){
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _collectionView = [self createCollectionViewWithFrame:self.view.bounds];
}

#pragma mark - CollectionView configuration
-(UICollectionView*) createCollectionViewWithFrame:(CGRect)frame{
    
    UICollectionViewFlowLayout* collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    [collectionViewFlowLayout setItemSize:CGSizeMake(frame.size.width/[_dataSource numberOfColumnsPerPage], frame.size.height/[_dataSource numberOfRowsPerPage])];
    [collectionViewFlowLayout setMinimumInteritemSpacing:0];
    [collectionViewFlowLayout setMinimumLineSpacing:0];
    
    UICollectionView* aCollectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:collectionViewFlowLayout];
    [self.view addSubview:aCollectionView];
    aCollectionView.backgroundColor = [UIColor clearColor];
    aCollectionView.showsHorizontalScrollIndicator = NO;
    aCollectionView.showsVerticalScrollIndicator = NO;
    aCollectionView.bounces = NO;
    
    aCollectionView.delegate = self;
    aCollectionView.dataSource = self;
    
    [aCollectionView registerClass:[_dataSource dashboardCellClass] forCellWithReuseIdentifier:[_dataSource cellReuseIdentifier]];
    
    return aCollectionView;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [_dataSource numberOfColumnsPerPage]*[_dataSource numberOfRowsPerPage];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    return [_dataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

#pragma mark - didReceiveMemoryWarning
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
