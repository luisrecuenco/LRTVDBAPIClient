// LRAddShowsViewController.m
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

#import "LRAddShowsViewController.h"
#import "LRTVDBAPIClient.h"
#import "LRShowDetailsViewController.h"
#import "LRTVDBAddShowCell.h"
#import "LRTVDBShowStorage.h"
#import "LRTVDBShow.h"

static NSTimeInterval const kTimeElapsedToPerformSearch = 0.75f;

@interface LRAddShowsViewController () <LRTVDBAddShowCellProtocol>

@property (nonatomic, copy) NSArray *shows;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, copy) NSString *searchingQuery;

@end

@implementation LRAddShowsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.searchBar becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    
    if (selectedIndexPath)
    {
        [self.tableView reloadRowsAtIndexPaths:@[selectedIndexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)dealloc
{
    [[LRTVDBAPIClient sharedClient] cancelShowsWithNameRequest:_searchingQuery];
    
    [self cancelCurrentShowsUpdates];
}

#pragma mark - UITableView datasource and delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.shows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LRTVDBAddShowCell *cell = [tableView dequeueReusableCellWithIdentifier:LRTVDBAddShowCellReuseIdentifier];
    cell.delegate = self;
    
    LRTVDBShow *show = self.shows[indexPath.row];
    cell.show = LRTVDBShowForID(show.showID) ?: show;
    
    return cell;
}

#pragma mark - UISearchBar Delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(performSearch)
                                               object:nil];
    
    [self performSearch];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [[LRTVDBAPIClient sharedClient] cancelShowsWithNameRequest:self.searchingQuery];
    
    [self removeFeedback];

    SEL targetSelector = @selector(performSearch);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:targetSelector
                                               object:nil];
    
    [self performSelector:targetSelector
               withObject:nil
               afterDelay:kTimeElapsedToPerformSearch];
}

- (void)performSearch
{
    if ([self.searchBar.text length] == 0) return;
    
    [[LRTVDBAPIClient sharedClient] cancelShowsWithNameRequest:self.searchingQuery];
    
    [self cancelCurrentShowsUpdates];

    self.searchingQuery = self.searchBar.text;
    
    [self showFeedback];
    
    __weak LRAddShowsViewController *wself = self;
    
    [[LRTVDBAPIClient sharedClient] showsWithName:self.searchingQuery
                                  completionBlock:^(NSArray *shows, NSError *error) {
                                      
                                      __strong LRAddShowsViewController *sself = wself;
                                      
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          
                                          [sself removeFeedback];
                                          
                                          if (shows.count == 0)
                                          {
                                              [sself showError];
                                          }
                                          else
                                          {
                                              sself.shows = shows;
                                              [sself.tableView reloadData];
                                              [sself updateShows];
                                          }
                                      });
                                  }];
}


- (void)showError
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"No shows found"
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)updateShows
{
    [[LRTVDBAPIClient sharedClient] updateShows:self.shows
                                  checkIfNeeded:NO
                                 updateEpisodes:YES
                                   updateImages:NO
                                   updateActors:NO
                                completionBlock:NULL];
}

- (void)cancelCurrentShowsUpdates
{
    // Do not cancel update of shows that have been added to the storage
    NSIndexSet *indexSet = [_shows indexesOfObjectsPassingTest:^BOOL(LRTVDBShow *show, NSUInteger idx, BOOL *stop) {
        
        return ![[LRTVDBShowStorage sharedStorage] existShow:show];
    }];
    
    [[LRTVDBAPIClient sharedClient] cancelUpdateOfShowsRequests:[_shows objectsAtIndexes:indexSet]
                                                 updateEpisodes:YES
                                                   updateImages:NO
                                                   updateActors:NO];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

#pragma mark - Feedback

- (void)showFeedback
{    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [spinner startAnimating];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
}

- (void)removeFeedback
{
    self.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - Dismiss controller

- (IBAction)goBack:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Prepare For Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowDetailsControllerSegue"])
    {
        LRShowDetailsViewController *showController = segue.destinationViewController;
        showController.show = [(LRTVDBAddShowCell *)sender show];
    }
}

#pragma mark - LRTVDBAddShowCell Protocol

- (void)addShowButtonWasTappedOnCell:(LRTVDBAddShowCell *)cell
{
    if ([[LRTVDBShowStorage sharedStorage] existShow:cell.show])
    {
        [[LRTVDBShowStorage sharedStorage] removeShow:cell.show];
    }
    else
    {
        [[LRTVDBShowStorage sharedStorage] addShow:cell.show];
    }
    
    // Reload cell to reflect changes.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.shows indexOfObjectIdenticalTo:cell.show]
                                                inSection:0];
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (BOOL)shouldShowSeriesAddedOnCell:(LRTVDBAddShowCell *)cell
{
    return [[LRTVDBShowStorage sharedStorage] existShow:cell.show];
}

@end
