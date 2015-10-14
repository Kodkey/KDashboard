//
//  CollectionViewEmbedderViewController.h
//  KDashboard
//
//  Created by COURELJordan on 13/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CollectionViewEmbedderViewControllerDataSource <NSObject>
@required
-(NSInteger)numberOfRowsPerPage;
-(NSInteger)numberOfColumnsPerPage;
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

-(Class)dashboardCellClass;
-(NSString*)cellReuseIdentifier;

@end

@protocol CollectionViewEmbedderViewControllerDelegate <NSObject>
@optional

@end

@interface CollectionViewEmbedderViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, assign) id<CollectionViewEmbedderViewControllerDataSource> dataSource;
@property (nonatomic, assign) id<CollectionViewEmbedderViewControllerDelegate> delegate;


@end
