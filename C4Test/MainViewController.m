//
//  ViewController.m
//  C4Test
//
//  Created by valentinkovalski on 2/4/15.
//  Copyright (c) 2015 valentinkovalski. All rights reserved.
//

#import "MainViewController.h"
#import "ImageCell.h"
#import "Constants.h"
#import "INTULocationManager.h"

@interface MainViewController ()
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) SortingView *sortingView;
@property (nonatomic, strong) UICollectionViewFlowLayout *defaultLayout;
@property (nonatomic, strong) NSIndexPath *indexPathBeforeRotation;
@end

#define VIEW_HEIGHT ([[UIScreen mainScreen] applicationFrame].size.height + (([UIApplication sharedApplication].statusBarHidden)?0:20))
#define VIEW_WIDTH [[UIScreen mainScreen] applicationFrame].size.width

#define TILE_WIDTH (VIEW_WIDTH/2)
#define TILE_HEIGHT (VIEW_HEIGHT/4)

#define TOP_BAR_HEIGHT 60

static NSString *ImageCellID = @"ImageCell";
static NSString *HeaderID = @"CollectionViewHeader";

const CGFloat separatorWidth = 1.0f;

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //layout
    self.defaultLayout = [[UICollectionViewFlowLayout alloc] init];
    self.defaultLayout.minimumInteritemSpacing = separatorWidth;
    self.defaultLayout.minimumLineSpacing = separatorWidth;
    self.defaultLayout.itemSize = CGSizeMake(TILE_WIDTH - separatorWidth, TILE_HEIGHT);
    self.defaultLayout.headerReferenceSize = CGSizeMake(VIEW_WIDTH, TOP_BAR_HEIGHT);
    self.collectionView.collectionViewLayout = self.defaultLayout;
    
    //other grid adjustments
    [self.collectionView registerClass:[ImageCell class] forCellWithReuseIdentifier:ImageCellID];
    [self.collectionView registerNib:[UINib nibWithNibName:@"SortingView" bundle:nil]
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                 withReuseIdentifier:HeaderID];
    
    //load data from bundle
    [self loadData];
    
    //add long press to delete gesture recognizer
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressGestureRecognizer.minimumPressDuration = 1; //seconds
    [self.collectionView addGestureRecognizer:longPressGestureRecognizer];
}

#pragma mark - Collection View data soure
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:ImageCellID forIndexPath:indexPath];
    cell.imageData = self.items[indexPath.row];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    self.sortingView = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:HeaderID forIndexPath:indexPath];
    self.sortingView.delegate = self;
    return self.sortingView;
}

#pragma mark - Collection view delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //switch to fullscreen swiping
    if(self.collectionView.collectionViewLayout == self.defaultLayout) {
        UICollectionViewFlowLayout *fullscreenLayout = [[UICollectionViewFlowLayout alloc] init];
        fullscreenLayout.itemSize = CGSizeMake(self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
        fullscreenLayout.minimumInteritemSpacing = 0;
        fullscreenLayout.minimumLineSpacing = 0;
        fullscreenLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        [self.collectionView setCollectionViewLayout:fullscreenLayout animated:YES completion:^(BOOL finished) {
            [collectionView setPagingEnabled:YES];
        }];
    } else {
        //switch back to grid
        [self.collectionView setCollectionViewLayout:self.defaultLayout animated:YES completion:^(BOOL finished) {
            [collectionView setPagingEnabled:NO];
        }];
    }
}

#pragma mark - Utils

- (void)loadData {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"imagesData" ofType:@"json"];
    NSData* data = [NSData dataWithContentsOfFile:filePath];
    __autoreleasing NSError* error = nil;
    NSArray *items = [NSJSONSerialization JSONObjectWithData:data
                                                     options:kNilOptions error:&error];
    
    if (error != nil || ![items isKindOfClass:[NSArray class]])
        NSLog(@"wrong json data file format");
    
    self.items = [items mutableCopy];
}

#pragma mark - Sorting delegate
- (void)sortUsingSortingMethod:(SortingMethod)sortingMethod {
    switch (sortingMethod) {
        case SortingMethodByName:
            [self sortByName];
            break;
        case SortingMethodByDistance:
            [self sortByDistance];
        default:
            break;
    }
}

- (void)sortByName {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kTitle ascending:YES];
    self.items = [[self.items sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
    [self.collectionView reloadData];
}

- (void)sortByDistance {
    //IMPORTANT: it's not recommended to set timeout to 0, accuracy will can be low in that case, but for the test it will save plenty of time..
    INTULocationManager *locMgr = [INTULocationManager sharedInstance];
    
    //using network activity indicator to save time
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [locMgr requestLocationWithDesiredAccuracy:INTULocationAccuracyCity
                                       timeout:0.0
                          delayUntilAuthorized:YES  // This parameter is optional, defaults to NO if omitted
                                         block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                             
                                             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                             
                                             if (status == INTULocationStatusSuccess) {
                                                 // Request succeeded, meaning achievedAccuracy is at least the requested accuracy, and
                                                 // currentLocation contains the device's current location.
                                                 [self sortByDistanceUsingLocation:currentLocation];
                                             }
                                             else if (status == INTULocationStatusTimedOut) {
                                                 // Wasn't able to locate the user with the requested accuracy within the timeout interval.
                                                 // However, currentLocation contains the best location available (if any) as of right now,
                                                 // and achievedAccuracy has info on the accuracy/recency of the location in currentLocation.
                                                 [self showAlertMessage:NSLocalizedString(@"Can't get location", @"")];
                                                 [self.sortingView reset];
                                                 
                                             }
                                             else {
                                                 // An error occurred, more info is available by looking at the specific status returned.
                                                 [self showAlertMessage:NSLocalizedString(@"Can't get location", @"")];
                                                 [self.sortingView reset];
                                             }
                                         }];
    
}

- (void)sortByDistanceUsingLocation:(CLLocation*)currentLocation {
    self.items = [[self.items sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        CLLocation *location1 = [[CLLocation alloc] initWithLatitude:[obj1[kLat] floatValue] longitude:[obj1[kLng] floatValue]];
        CLLocation *location2 = [[CLLocation alloc] initWithLatitude:[obj2[kLat] floatValue] longitude:[obj2[kLng] floatValue]];
        
        CLLocationDistance distanceToLocation1 = [currentLocation distanceFromLocation:location1];
        CLLocationDistance distanceToLocation2 = [currentLocation distanceFromLocation:location2];
        
        if (distanceToLocation1 > distanceToLocation2) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        if (distanceToLocation2 < distanceToLocation2) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
        
    }] mutableCopy];
    [self.collectionView reloadData];
}

- (void)showAlertMessage:(NSString*)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Alert title", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Gesture recognizers
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    CGPoint p = [gestureRecognizer locationInView:self.collectionView];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    if (indexPath == nil){
        NSLog(@"couldn't find index path");
    } else {
        [self.items removeObjectAtIndex:indexPath.row];
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    }
}

#pragma mark - Orientations support
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    
    //do nothing for grid layout
    if(layout == self.defaultLayout)
        return;
    
    //save index path of visible item for later paging adjustment
    self.indexPathBeforeRotation = [[self.collectionView indexPathsForVisibleItems] firstObject];
    [self.collectionView scrollToItemAtIndexPath:self.indexPathBeforeRotation atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    
    //do nothing for grid layout
    if(layout == self.defaultLayout)
        return;

    layout.itemSize = CGSizeMake(self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    
        //force layout
        [layout invalidateLayout];

    
    //adjust paging
    [self.collectionView setContentOffset:CGPointMake(self.indexPathBeforeRotation.row * layout.itemSize.width, 0)];
}

//no time to handle console issues and issues with blinking in swiping mode during rotation
//no time for web content loading and KIF

@end
