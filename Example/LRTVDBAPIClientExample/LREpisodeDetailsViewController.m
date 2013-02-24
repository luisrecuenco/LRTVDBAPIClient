// LREpisodeDetailsViewController.m
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

#import "LREpisodeDetailsViewController.h"
#import "UIImageView+LRNetworking.h"
#import "LRTVDBEpisode.h"
#import "LRUIBeautifier.h"
#import "LRTVDBShow.h"

@interface LREpisodeDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *episodeImageView;
@property (weak, nonatomic) IBOutlet UITextView *episodeOverviewTextView;

@end

@implementation LREpisodeDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    LRApplyStandardShadowToView(self.episodeImageView);
    
    self.title = self.episode.title;
    [self.episodeImageView setImageWithURL:self.episode.imageURL];
    self.episodeOverviewTextView.text = self.episode.overview ?: @"No information available";
    
    if (![UIActivityViewController class]) // iOS 5
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (IBAction)share:(id)sender
{
    NSString *message = [NSString stringWithFormat:@"I've watched \"%@\" (S%02dE%02d) of %@",
                         self.episode.title,
                         self.episode.seasonNumber.unsignedIntegerValue,
                         self.episode.episodeNumber.unsignedIntegerValue,
                         self.episode.show.name];
    
    UIImage *image = self.episodeImageView.image;
    
    NSArray *activityItems = [NSArray arrayWithObjects:message, image, nil];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                     applicationActivities:nil];
    
    activityController.excludedActivityTypes = @[UIActivityTypeAssignToContact,
                                                 UIActivityTypeMessage,
                                                 UIActivityTypeSaveToCameraRoll,
                                                 UIActivityTypePrint,
                                                 UIActivityTypePostToWeibo,
                                                 UIActivityTypeCopyToPasteboard,
                                                 UIActivityTypeMail];
    
    [self presentViewController:activityController
                       animated:YES
                     completion:^{
                         // excludedActivityTypes is surprisingly leaking if not set to nil.
                         activityController.excludedActivityTypes = nil;
                     }];
}

- (void)dealloc
{
    [_episodeImageView cancelImageOperation];
}

@end
