# KDashboard

## What is it ?

  KDashboard is a two-classes package for iOS 7+ application, allowing to create a iOS/Android-main-screen-alike view. This acts as a UICollectionView displayed on multiple pages and allow some user interaction on displayed cells :
  * swapping cells
  * inserting cells
  * deleting cells
  * creating groups with two cells

  To do so, you have to long-press cells to start dragging them. Then you can drop them wherever you want. This will perform a specific action according to where you drop it and how long you kept it over an another cell. Remember, this work like an iOS/Android main screen

## Demonstration

https://appetize.io/app/cgk7zpc5a2x163dr47qrkerxmw

## Usage

 Well I will describe my object usage as simple as possible:

  To use KDashboard, you have to :
  * Import KDashboard and CollectionViewEmbedderViewController classes to your project.
  * Prepare an UICollectionViewCell subclass to display in the KDashboard.
  * Prepare an UIViewController subclass where you will embed KDashboard.
  * Call this method to create your KDashboard :

```objective-c
-(id) initWithFrame:(CGRect)frame andDataSource:(id<KDashboardDataSource>)dataSource andDelegate:(id<KDashboardDelegate>)delegate andCellClass:(Class)cellClass andReuseIdentifier:(NSString*)identifier andAssociateToThisViewController:(UIViewController*)viewController;
```

with:
 1. frame is the frame you want to give to your KDashboard in its parent UIViewController.
 2. dataSource to customize your KDashboard cells.
 3. delegate to get callbacks from your KDashboard
 4. cellClass is your UICollectionViewCell subclass definition
 5. reuseIdentifier is a random String you put there and you have to keep it for recycling your cells
 6. viewController is the parent UIViewController that will embed your KDashboard


* Set some KDashboard options :

```objective-c
@property (nonatomic) BOOL bounces;

@property (nonatomic) BOOL showPageControlWhenOnlyOnePage;
@property (nonatomic) BOOL showPageControl;

@property (nonatomic) BOOL enableDragAndDrop;
@property (nonatomic) BOOL enableSwappingAction;
@property (nonatomic) BOOL enableInsertingAction;
@property (nonatomic) BOOL enableGroupCreation;
```

  * Call this method to display your KDashboard :

```objective-c
-(void) display();
```

  * Implement those KDashboardDataSource methods :

```objective-c
-(NSUInteger)rowCountPerPageInDashboard:(KDashboard*)dashboard;
-(NSUInteger)columnCountPerPageInDashboard:(KDashboard*)dashboard;
-(NSUInteger)cellCountInDashboard:(KDashboard*)dashboard;
-(UICollectionViewCell*)dashboard:(KDashboard*)dashboard cellForItemAtIndex:(NSUInteger)index;
```

Here is what can look like the dashboard:cellForItemAtIndex method:

```objective-c
-(CollectionViewCell*)dashboard:(KDashboard*)dashboard cellForItemAtIndex:(NSUInteger)index{
    CollectionViewCell* cell = nil; //cell is your custom UICollectionViewCell subclass

    cell = (CollectionViewCell*) [dashboard dequeueReusableCellWithIdentifier:CELL_NAME forIndex:index]; //CELL_NAME here is the same String you put when creating your KDashboard

    [cell customizeWithImage:[UIImage imageNamed:@"imagecell.png"] andText:[NSString stringWithFormat:@"cell%d",index]]; //after dequeueing your cell with the previous method, you have to customize it according to the current index
    
    return cell; // return your freshly customized cell
}
```

  * Implement KDashboardDelegate methods you want :

```objective-c
-(void)dashboard:(KDashboard*)dashboard userStartedDragging:(UIView*)draggedCell;
-(void)endDraggingFromDashboard:(KDashboard*)dashboard;
-(void)dashboard:(KDashboard *)dashboard userDraggedCellInsideDashboard:(UIView *)draggedCell;
-(void)dashboard:(KDashboard *)dashboard userDraggedCellOutsideDashboard:(UIView *)draggedCell;

-(void)dashboard:(KDashboard*)dashboard userTappedOnACellAtThisIndex:(NSInteger)index;

-(void)dashboard:(KDashboard*)dashboard swapCellAtIndex:(NSInteger)sourceIndex withCellAtIndex:(NSInteger)destinationIndex;
-(void)dashboard:(KDashboard*)dashboard insertCellFromIndex:(NSInteger)sourceIndex toIndex:(NSInteger)destinationIndex;
-(void)dashboard:(KDashboard*)dashboard deleteCellAtIndex:(NSInteger)index;

-(void)dashboard:(KDashboard *)dashboard canCreateGroupAtIndex:(NSInteger)index withSourceIndex:(NSInteger)sourceIndex;
-(void)dismissGroupCreationPossibilityFromDashboard:(KDashboard*)dashboard;
-(void)dashboard:(KDashboard*)dashboard addGroupAtIndex:(NSInteger)index withCellAtIndex:(NSInteger)sourceIndex;
```

User interactions allowed by KDashboard are not effective if you do not update your data list through those previous callback methods. They will be refreshed whenever you navigate through KDashboard pages.

  * Voilà !
