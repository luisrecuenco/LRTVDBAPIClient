// LRTVDBAddShowCell.m
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

#import "LRTVDBAddShowCell.h"
#import "LRTVDBShow.h"
#import "UIImageView+LRNetworking.h"
#import "LRSwitchButton.h"
#import "LRUIBeautifier.h"

static void *kObservingEpisodesContext;

NSString *const LRTVDBAddShowCellReuseIdentifier = @"LRTVDBAddShowCellReuseIdentifier";

static NSString *const kLoadingIndicator = @"...";

@interface LRTVDBAddShowCell ()

@property (nonatomic, strong) LRTVDBShow *show;

@end

@implementation LRTVDBAddShowCell

- (void)awakeFromNib
{
    LRApplyCurlShadowToView(self.showImageView);
}

- (void)setShow:(LRTVDBShow *)show
{
    if (show != _show)
    {
        [_show removeObserver:self
                   forKeyPath:LRTVDBShowAttributes.episodes];
        
        _show = show;
        
        [_show addObserver:self
                forKeyPath:LRTVDBShowAttributes.episodes
                   options:0
                   context:&kObservingEpisodesContext];
        
        [self generateUI];
    }
}

- (void)generateUI
{
    self.nameLabel.text = _show.name;
    self.networkLabel.text = [self generateNetworkLabelText];
    self.statusLabel.text = [self generateStatusLabelText];
    
    [self.showImageView setImageWithURL:_show.posterURL
                       placeholderImage:[UIImage imageNamed:@"PosterPlaceholder"]];
    
    self.addShowButton.filled = [self.delegate shouldShowSeriesAddedOnCell:self];
}

- (void)dealloc
{
    [_show removeObserver:self
               forKeyPath:LRTVDBShowAttributes.episodes];
}

#pragma mark - KVO handling

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &kObservingEpisodesContext)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self generateUI];
        });
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSString *)generateNetworkLabelText
{
    if (self.show.episodes == nil) return kLoadingIndicator;
    
    return self.show.network ?: @"Unknown network";
}

- (NSString *)generateStatusLabelText
{
    if (self.show.episodes == nil) return kLoadingIndicator;
    
    switch (self.show.status)
    {
        case LRTVDBShowStatusUnknown:
            return @"Unknown status";
            break;
        case LRTVDBShowStatusTBA:
            return @"Continuing";
            break;
        case LRTVDBShowStatusUpcoming:
            return @"Continuing";
            break;
        case LRTVDBShowStatusEnded:
            return @"Ended";
            break;
        default:
            NSAssert(NO, @"Wrong branch");
            break;
    }
}

- (IBAction)addShowButtonTapped:(id)sender
{
    [self.delegate addShowButtonWasTappedOnCell:self];
}

@end
