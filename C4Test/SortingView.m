//
//  SortingView.m
//  C4Test
//
//  Created by valentinkovalski on 2/4/15.
//  Copyright (c) 2015 valentinkovalski. All rights reserved.
//

#import "SortingView.h"
#import "Constants.h"

@implementation SortingView
- (void)awakeFromNib {
    [self.segmentedControl setTitle:NSLocalizedString(@"By name", @"") forSegmentAtIndex:0];
    [self.segmentedControl setTitle:NSLocalizedString(@"By distance", @"") forSegmentAtIndex:1];
}

- (IBAction)valueChanged:(UISegmentedControl*)sender {
    [self.delegate sortUsingSortingMethod:sender.selectedSegmentIndex];
}

- (void)reset {
    self.segmentedControl.selectedSegmentIndex = 0;
}

@end
