// LRShowDetailsViewController.m
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

#import "LRShowDetailsViewController.h"
#import "UIImageView+LRNetworking.h"
#import "LRTVDBShow.h"
#import "LRTVDBShowStorage.h"
#import "LRUIBeautifier.h"

@interface LRShowDetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *fanartImageView;
@property (weak, nonatomic) IBOutlet UITextView *showOverviewTextView;

@end

@implementation LRShowDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self.show addObserver:self
                forKeyPath:LRTVDBShowAttributes.fanartURL
                   options:0
                   context:NULL];
    
    self.title = self.show.name;
    [self.fanartImageView setImageWithURL:self.show.fanartURL];
    self.showOverviewTextView.text = self.show.overview ?: @"No information available";
    
    if ([[LRTVDBShowStorage sharedStorage] existShow:self.show])
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    LRApplyStandardShadowToView(self.fanartImageView);
}

#pragma mark - Add Show

- (IBAction)addShow:(id)sender
{
    [[LRTVDBShowStorage sharedStorage] addShow:self.show];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - KVO update

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.fanartImageView setImageWithURL:self.show.fanartURL];
    });
}

- (void)dealloc
{
    [_fanartImageView cancelImageOperation];
    
    [_show removeObserver:self
               forKeyPath:LRTVDBShowAttributes.fanartURL];
}

@end
