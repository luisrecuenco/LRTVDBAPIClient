// LRShowEpisodesViewController.m
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

#import "LRShowEpisodesViewController.h"
#import "LRTVDBShow.h"
#import "LRTVDBEpisode.h"
#import "LRTVDBEpisodeCell.h"
#import "LREpisodeDetailsViewController.h"
#import "UIImageView+LRNetworking.h"
#import "LRShowDetailsViewController.h"
#import "LRUIBeautifier.h"

@interface LRShowEpisodesViewController () <LRTVDBEpisodeCellProtocol>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIImageView *bannerImageView;

@property (nonatomic, assign) BOOL showHasNoEpisodes;

@end

@implementation LRShowEpisodesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = self.show.name;
    
    [self.show addObserver:self
                forKeyPath:LRTVDBShowAttributes.episodes
                   options:0
                   context:NULL];
    
    [self.show addObserver:self
                forKeyPath:LRTVDBShowAttributes.lastEpisode
                   options:0
                   context:NULL];
    
    // Put off till other UI operation finishes
    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollToCorrectEpisode];
    });
    
    self.showHasNoEpisodes = (self.show.episodes == nil);
    
    // Show feedback if necessary
    if (self.showHasNoEpisodes)
    {
        // We don't have the episodes yet, showing feedback
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [spinner startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    }
    
    [self.bannerImageView setImageWithURL:self.show.bannerURL];
    
    LRApplyStandardShadowToView(self.bannerImageView);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow]
                                  animated:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView reloadData];
        
        if (self.showHasNoEpisodes)
        {
            [self scrollToCorrectEpisode];
            
            // Remove feedback
            self.navigationItem.rightBarButtonItem = nil;
        }
        
        self.showHasNoEpisodes = (self.show.episodes == nil);
    });
}

- (void)scrollToCorrectEpisode
{
    LRTVDBEpisode *correctEpisode = self.show.lastEpisodeSeen ?: self.show.lastEpisode;
    
    if (correctEpisode == nil) return;
    
    NSArray *episodes = [self.show episodesForSeason:correctEpisode.seasonNumber];
    
    NSUInteger indexToScroll = MIN(correctEpisode.episodeNumber.integerValue, [episodes count]);
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexToScroll - 1
                                                inSection:correctEpisode.seasonNumber.integerValue];
    
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:NO];
}

#pragma mark - UITableView datasource and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.show.numberOfSeasons.integerValue + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.show episodesForSeason:@(section)].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{        
    LRTVDBEpisodeCell *cell = [tableView dequeueReusableCellWithIdentifier:LRTVDBEpisodeCellReuseIdentifier];
    cell.delegate = self;
    cell.episode = [self.show episodesForSeason:@(indexPath.section)][indexPath.row]; 
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger numberOfEpisodes = [self.show episodesForSeason:@(section)].count;
    
    return numberOfEpisodes > 0 ? [NSString stringWithFormat:@"Season %d (%d episodes)",
                                   section, numberOfEpisodes] : nil;
}

- (void)dealloc
{
    [_bannerImageView cancelImageOperation];
    [_show removeObserver:self forKeyPath:LRTVDBShowAttributes.lastEpisode];
    [_show removeObserver:self forKeyPath:LRTVDBShowAttributes.episodes];
}

#pragma mark - Prepare For Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"EpisodeDetailsControllerSegue"])
    {
        LREpisodeDetailsViewController *episodesController = segue.destinationViewController;
        episodesController.episode = [(LRTVDBEpisodeCell *)sender episode];
    }
    else if ([segue.identifier isEqualToString:@"BannerImageTappedControllerSegue"] ||
             [segue.identifier isEqualToString:@"InfoButtonTappedControllerSegue"])
    {
        LRShowDetailsViewController *showDetailsController = segue.destinationViewController;
        showDetailsController.show = self.show;
    }
}

#pragma mark - LRTVDBEpisodeCell Protocl

- (void)episodeSeenButtonTappedOnCell:(LRTVDBEpisodeCell *)cell
{
    LRTVDBEpisode *validEpisode = nil;

    if (cell.episode == self.show.lastEpisodeSeen)
    {
        NSUInteger index = [self.show.episodes indexOfObjectIdenticalTo:cell.episode];
        
        if (index != NSNotFound && index > 0)
        {
            validEpisode = self.show.episodes[index - 1];
        }
    }
    else
    {
        validEpisode = cell.episode;
    }
    
    self.show.lastEpisodeSeen = validEpisode;
    
    [self.tableView reloadData];
}

@end
