//
//  SVWallView.h
//  Walls
//
//  Created by Sebastien Villar on 24/01/14.
//  Copyright (c) 2014 Sebastien Villar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVWallView : UIView
@property (assign, readonly) CGRect shownRect;

typedef enum {
    kSVWallViewTopOriented,
    kSVWallViewBottomOriented,
    kSVWallViewRounded
} kSVWallViewType;

- (id)initWithFrame:(CGRect)frame startType:(kSVWallViewType)start
            endType:(kSVWallViewType)end
          leftColor:(UIColor*)leftColor
        centerColor:(UIColor*)centerColor
        rightColor:(UIColor*)rightColor;
- (void)showRect:(CGRect)rect animated:(BOOL)animated withFinishBlock:(void(^)(void))block;
@end
