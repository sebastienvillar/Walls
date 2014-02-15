//
//  SVGamesTableViewController.m
//  Walls
//
//  Created by Sebastien Villar on 28/01/14.
//  Copyright (c) 2014 Sebastien Villar. All rights reserved.
//

#import <GameKit/GameKit.h>
#import "SVGamesTableViewController.h"
#import "SVGameViewController.h"
#import "SVTheme.h"
#import "SVCustomView.h"
#import "SVGameTableViewCell.h"

static NSString *spaceCellIdentifer = @"SpaceCell";
static NSString *gameCellIdentifier = @"GameCell";

@interface SVGamesTableViewController ()
@property (strong) NSMutableArray* inProgressGames;
@property (strong) NSMutableArray* endedGames;
@property (strong) SVGameViewController* currentController;

- (void)newGame;
- (void)loadGame:(SVGame*)game;
- (void)loadGames;

- (void)didClickAddButton;
@end

@implementation SVGamesTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _inProgressGames = [[NSMutableArray alloc] init];
        _endedGames = [[NSMutableArray alloc] init];
        [[GKLocalPlayer localPlayer] unregisterAllListeners];
        [[GKLocalPlayer localPlayer] registerListener:self];
        [self loadGames];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundColor = [SVTheme sharedTheme].lightSquareColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:SVGameTableViewCell.class forCellReuseIdentifier:gameCellIdentifier];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:spaceCellIdentifer];
    UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"New" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(didClickAddButton) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 500, 100, 30);
    
    [self.view addSubview:button];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////

- (void)newGame {
    GKMatchRequest* request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    GKTurnBasedMatchmakerViewController* controller = [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:request];
    [self presentViewController:controller
                       animated:YES
                     completion:nil];
    controller.turnBasedMatchmakerDelegate = self;
}

- (void)loadGame:(SVGame*)game {
    SVGameViewController* controller = [[SVGameViewController alloc] initWithGame:game];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:NO];
    self.currentController = controller;
}

- (void)loadGames {
    [GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error) {
        if (error) {
            NSLog(@"error : %@", error);
            return;
        }
        int i = 0;
        for (GKTurnBasedMatch* match in matches) {
            [match loadMatchDataWithCompletionHandler:nil];
            NSMutableArray* playerIDs = [[NSMutableArray alloc] init];
            for (GKTurnBasedParticipant* participant in match.participants) {
                [playerIDs addObject:participant.playerID];
            }
            [GKPlayer loadPlayersForIdentifiers:playerIDs
                          withCompletionHandler:^(NSArray *players, NSError *error) {
                              for (GKPlayer* player in players) {
                                  if ([player.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
                                      
                                  }
                              }
            }];
            SVGame* game = [SVGame gameWithMatch:match];
            if (game.match.status == GKTurnBasedMatchStatusEnded) {
                [self.endedGames addObject:game];
            }
            else {
                [self.inProgressGames addObject:game];
            }
            i++;
        }
        [self.tableView reloadData];
    }];
}

//////////////////////////////////////////////////////
// Buttons Targets
//////////////////////////////////////////////////////

- (void)didClickAddButton {
    [self newGame];
}

//////////////////////////////////////////////////////
// Delegates
//////////////////////////////////////////////////////

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFindMatch:(GKTurnBasedMatch *)match {
    NSLog(@"found match: %@", match.matchID);
    [self loadGame:[SVGame gameWithMatch:match]];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController playerQuitForMatch:(GKTurnBasedMatch *)match {
    NSLog(@"quit");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)turnBasedMatchmakerViewControllerWasCancelled:(GKTurnBasedMatchmakerViewController *)viewController {
    NSLog(@"cancelled");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    NSLog(@"fail");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)player:(GKPlayer *)player receivedTurnEventForMatch:(GKTurnBasedMatch *)match didBecomeActive:(BOOL)didBecomeActive {
    if (self.currentController && [match.matchID isEqualToString:self.currentController.game.match.matchID]) {
        [GKTurnBasedMatch loadMatchWithID:match.matchID withCompletionHandler:^(GKTurnBasedMatch *match, NSError *error) {
            SVGame* game = [SVGame gameWithMatch:match];
            if (game.turns.count > self.currentController.game.turns.count) {
                [self.currentController opponentPlayerDidPlayTurn:game];
                [[GKLocalPlayer localPlayer] unregisterAllListeners];
                [[GKLocalPlayer localPlayer] registerListener:self];
            }
        }];
    }
    else {
        //Refresh matches
    }
}

- (void)player:(GKPlayer *)player didRequestMatchWithPlayers:(NSArray *)playerIDsToInvite {
    NSLog(@"did request match");
}

- (void)player:(GKPlayer *)player matchEnded:(GKTurnBasedMatch *)match {
    NSLog(@"match ended");
}

- (void)gameViewController:(SVGameViewController *)controller didPlayTurn:(SVGame *)game ended:(BOOL)ended{
    NSData* data = [game data];
    GKTurnBasedParticipant* nextParticipant;
    for (GKTurnBasedParticipant* participant in game.match.participants) {
        if (![participant.playerID isEqualToString:game.match.currentParticipant.playerID])
            nextParticipant = participant;
    }

    if (ended) {
        for (GKTurnBasedParticipant* participant in game.match.participants) {
            if ([participant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID])
                participant.matchOutcome = GKTurnBasedMatchOutcomeWon;
            else
                participant.matchOutcome = GKTurnBasedMatchOutcomeLost;
        }
        [game.match endMatchInTurnWithMatchData:data completionHandler:^(NSError *error) {
            NSLog(@"ended");
        }];
    }
    else {
        [game.match endTurnWithNextParticipants:[NSArray arrayWithObject:nextParticipant]
                                    turnTimeout:GKTurnTimeoutNone
                                      matchData:data
                              completionHandler:^(NSError *error) {
                                    NSLog(@"sent");
                              }];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.inProgressGames.count;
    }
    return self.endedGames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
//    GKTurnBasedMatch* match = [self.matches objectAtIndex:indexPath.row];
//    cell.textLabel.text = match.creationDate.description;
    if (indexPath.row % 2 == 1) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:spaceCellIdentifer forIndexPath:indexPath];
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else {
        SVGameTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:gameCellIdentifier forIndexPath:indexPath];
        if (indexPath.section == 0) {
            SVGame* game = [self.inProgressGames objectAtIndex:ceil(indexPath.row / 2)];
            if ([game.match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
                [cell setText:@"Your turn"];
                [cell setColor:[SVTheme sharedTheme].localPlayerColor];
            }
            else {
                [cell setText:@"Waiting"];
                [cell setColor:[SVTheme sharedTheme].opponentPlayerColor];
            }
        }
        else {
            SVGame* game = [self.endedGames objectAtIndex:ceil(indexPath.row / 2)];
            for (GKTurnBasedParticipant* participant in game.match.participants) {
                if ([participant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
                    if (participant.matchOutcome == GKTurnBasedMatchOutcomeWon) {
                        [cell setText:@"Won"];
                    }
                    else {
                        [cell setText:@"Lost"];
                    }
                }
            }
            [cell setColor:[SVTheme sharedTheme].endedGameColor];
        }
        return cell;
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray* games;
    if (indexPath.section == 0)
        games = self.inProgressGames;
    else
        games = self.endedGames;
    
    SVGame* game = [games objectAtIndex:ceil(indexPath.row / 2)];
    //Check if data
    [self loadGame:game];
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SVCustomView* view = [[SVCustomView alloc] init];
    __weak SVCustomView* weakSelf = view;
    [view drawBlock:^(CGContextRef context) {
        UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectMake(20,
                                                                         27,
                                                                         weakSelf.frame.size.width - 40,
                                                                         1)];
        [[UIColor whiteColor] setFill];
        [path fill];
    }];
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(20,
                                                               8,
                                                               100,
                                                               15)];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    
    NSMutableAttributedString* text;
    if (section == 0) {
        text = [[NSMutableAttributedString alloc] initWithString:@"In progress"];
        [text addAttribute:NSKernAttributeName value:@2 range:NSMakeRange(0, 10)];
    }
    else {
        text = [[NSMutableAttributedString alloc] initWithString:@"Completed"];
        [text addAttribute:NSKernAttributeName value:@2 range:NSMakeRange(0, 8)];
    }
    label.attributedText = text;
    [view addSubview:label];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 36;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2 == 1) {
        return 8;
    }
    return 42;
}

@end
