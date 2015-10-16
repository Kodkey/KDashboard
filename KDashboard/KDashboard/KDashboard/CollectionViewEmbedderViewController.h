//
//  CollectionViewEmbedderViewController.h
//  KDashboard
//
//  Created by COURELJordan on 13/10/2015.
//  Copyright (c) 2015 COURELJordan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CollectionViewEmbedderViewController;
@protocol CollectionViewEmbedderViewControllerDataSource <NSObject>
@required
-(NSUInteger)maxRowCount;
-(NSUInteger)maxColumnCount;
-(NSInteger)numberOfItemsInThisCollectionViewEmbedderViewController:(CollectionViewEmbedderViewController*)collectionViewEmbedderViewController;
-(UICollectionViewCell *)collectionViewEmbedderViewController:(CollectionViewEmbedderViewController*)collectionViewEmbedder cellForItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol CollectionViewEmbedderViewControllerDelegate <NSObject>
@optional
- (void)collectionViewEmbedder:(CollectionViewEmbedderViewController *)collectionViewEmbedder didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface CollectionViewEmbedderViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) UICollectionView* collectionView;
@property (nonatomic) NSInteger pageIndex;

@property (nonatomic, assign) id<CollectionViewEmbedderViewControllerDataSource> dataSource;
@property (nonatomic, assign) id<CollectionViewEmbedderViewControllerDelegate> delegate;

- (id) initWithFrame:(CGRect)frame andDataSource:(id<CollectionViewEmbedderViewControllerDataSource>)dataSource andDelegate:(id<CollectionViewEmbedderViewControllerDelegate>)delegate andCellClass:(Class)cellClass andReuseIdentifier:(NSString*)identifier;
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

@end
