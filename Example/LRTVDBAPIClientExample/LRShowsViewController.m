// LRShowsViewController.m
//
// Copyright (c) 2013 Luis Recuenco
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LRShowsViewController.h"
#import "LRTVDBAPIClient.h"
#import "LRTVDBShowCell.h"
#import "LRShowEpisodesViewController.h"
#import "LRTVDBShowStorage.h"
#import "LRTVDBShow.h"
#import "NSDate+LRTVDBAdditions.h"

@interface LRShowsViewController () <LRShowStorageDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, copy) NSArray *shows;

@property (nonatomic, strong) NSDate *lastEpisodesRefresh;
@property (nonatomic, strong) NSDate *lastShowsUpdate;

@property (nonatomic, assign) BOOL shouldScrollWhenAddingShow;

@end

@implementation LRShowsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [LRTVDBShowStorage sharedStorage].delegate = self;
    
    if ([UIRefreshControl class])
    {
        self.refreshControl = [[UIRefreshControl alloc] init];
        
        [self.refreshControl addTarget:self
                                action:@selector(updateShows)
                      forControlEvents:UIControlEventValueChanged];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.shouldScrollWhenAddingShow = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.shouldScrollWhenAddingShow = YES;
    
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableView datasource and delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.shows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LRTVDBShowCell *cell = [tableView dequeueReusableCellWithIdentifier:LRTVDBShowCellReuseIdentifier];
    cell.show = self.shows[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [[LRTVDBShowStorage sharedStorage] removeShow:self.shows[indexPath.row]];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (NSArray *)shows
{
    if (_shows == nil)
    {
        _shows = [[LRTVDBShowStorage sharedStorage].shows copy];
    }
    return _shows;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if ([self shouldRefreshEpisodesInformation])
    {
        [self refreshEpisodesInformation];
    }

    if ([self shouldUpdateShows])
    {
        [self updateShows];
    }
    else
    {
        [self updatePendingShows];
    }
}

- (void)updatePendingShows
{
    NSIndexSet *indexSet = [self.shows indexesOfObjectsPassingTest:^BOOL(LRTVDBShow *show, NSUInteger idx, BOOL *stop) {
       
        return show.episodes == nil;
    }];
    
    NSArray *showsToUpdate = [self.shows objectsAtIndexes:indexSet];
    
    [[LRTVDBAPIClient sharedClient] updateShows:showsToUpdate
                                  checkIfNeeded:NO
                                 updateEpisodes:YES
                                   updateImages:YES
                                   updateActors:NO
                                completionBlock:NULL];
}

- (void)refreshEpisodesInformation
{
    self.lastEpisodesRefresh = [NSDate date];
    
    [self.shows makeObjectsPerformSelector:@selector(refreshEpisodesInfomation)];
    
    [[LRTVDBShowStorage sharedStorage] reloadShows];
    
    self.shows = nil;
    [self.tableView reloadData];
}

- (void)updateShows
{
    self.lastShowsUpdate = [NSDate date];
    
    if ([UIRefreshControl class])
    {
        [self.refreshControl beginRefreshing];
    }
    
    __weak LRShowsViewController *wself = self;
    
    [[LRTVDBAPIClient sharedClient] updateShows:self.shows
                                  checkIfNeeded:NO
                                 updateEpisodes:YES
                                   updateImages:NO
                                   updateActors:NO
                                completionBlock:^(BOOL finished) {
                                    
                                    __strong LRShowsViewController *sself = wself;
                                    
                                    [[LRTVDBShowStorage sharedStorage] reloadShows];
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        
                                        if ([UIRefreshControl class])
                                        {
                                            [sself.refreshControl endRefreshing];
                                        }
                                        
                                        sself.shows = nil;
                                        [sself.tableView reloadData];
                                    });
                                }];
}

- (BOOL)shouldRefreshEpisodesInformation
{
    if (self.lastEpisodesRefresh == nil) return YES;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                               fromDate:[self.lastEpisodesRefresh dateByIgnoringTime]
                                                 toDate:[[NSDate date] dateByIgnoringTime]
                                                options:0];
    return components.day > 0;
}

- (BOOL)shouldUpdateShows
{
    if (self.lastShowsUpdate == nil) return YES;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                               fromDate:[self.lastShowsUpdate dateByIgnoringTime]
                                                 toDate:[[NSDate date] dateByIgnoringTime]
                                                options:0];
    return components.day > 0;
}

#pragma mark - LRShowStorageDelegate delegate

- (void)showStorageDidAddShow:(LRTVDBShow *)show
{
    self.shows = nil;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.shows indexOfObject:show]
                                                inSection:0];
    
    [self.tableView insertRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationRight];
    
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:YES];
}

- (void)showStorageDidDeleteShow:(LRTVDBShow *)show
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.shows indexOfObject:show]
                                                inSection:0];
    
    self.shows = nil; // Regenerate
    
    [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationLeft];
}

- (void)showStorageDidUpdateShow:(LRTVDBShow *)show
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:[self.shows indexOfObject:show]
                                                        inSection:0];
        self.shows = nil; // Regenerate
        
        NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:[self.shows indexOfObject:show]
                                                      inSection:0];
        
        // Cell will get updated via KVO. iOS 6 didn't fix this bug:
        // http://openradar.appspot.com/10457435
        [self.tableView moveRowAtIndexPath:fromIndexPath
                               toIndexPath:toIndexPath];
        
        if (self.shouldScrollWhenAddingShow)
        {
            [self.tableView scrollToRowAtIndexPath:toIndexPath
                                  atScrollPosition:UITableViewScrollPositionBottom
                                          animated:YES];
        }
    });
}

#pragma mark - Prepare For Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowEpisodesControllerSegue"])
    {
        LRShowEpisodesViewController *episodesController = segue.destinationViewController;
        episodesController.show = [(LRTVDBShowCell *)sender show];
    }
}

@end
