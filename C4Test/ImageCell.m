//
//  ImageCell.m
//  C4Test
//
//  Created by valentinkovalski on 2/4/15.
//  Copyright (c) 2015 valentinkovalski. All rights reserved.
//

#import "ImageCell.h"
#import "UIImageView+AFNetworking.h"
#import "Constants.h"

@interface ImageCell ()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation ImageCell
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.imageView];
    }
    return self;
}

- (void)setImageData:(NSDictionary *)imageData {
    _imageData = imageData;
    
    NSURL *url = [NSURL URLWithString:self.imageData[kUrl]];
    
    //load image async
    [self.imageView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"Loading"]];
}

@end
