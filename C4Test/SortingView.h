//
//  SortingView.h
//  C4Test
//
//  Created by valentinkovalski on 2/4/15.
//  Copyright (c) 2015 valentinkovalski. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SortingMethod) {
    SortingMethodByName = 0,
    SortingMethodByDistance,
};

@protocol SortingDelegate<NSObject>
- (void)sortUsingSortingMethod:(SortingMethod)sortingMethod;
@end

@interface SortingView : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

- (IBAction)valueChanged:(id)sender;

@property (nonatomic, weak) id<SortingDelegate> delegate;


//resets selection in segmented control to 0
- (void)reset;
@end
