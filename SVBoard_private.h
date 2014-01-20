//
//  SVBoard_private.h
//  Walls
//
//  Created by Sebastien Villar on 19/01/14.
//  Copyright (c) 2014 Sebastien Villar. All rights reserved.
//

#import "SVBoard.h"

@interface SVBoard ()
@property (assign) CGSize size;
@property (strong) NSMutableArray* walls;
@property (strong) NSMutableArray* playerPositions;
@property (strong) NSArray* playerGoalsY;

- (NSArray*)movesForPlayer:(kSVPlayer)player;
- (BOOL)isGoalReachableByPlayer:(kSVPlayer)player;

@end
