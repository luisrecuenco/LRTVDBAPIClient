// LRTVDBShowCell.m
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

#import "LRTVDBShowCell.h"
#import "LRTVDBShow.h"
#import "LRTVDBEpisode.h"
#import "LRUIBeautifier.h"
#import "UIImageView+LRNetworking.h"

static void *kObservingEpisodesContext;

NSString *const LRTVDBShowCellReuseIdentifier = @"LRTVDBShowCellReuseIdentifier";

static NSString *const kLoadingIndicator = @"...";

@interface LRTVDBShowCell ()

@property (nonatomic, strong) LRTVDBShow *show;

@end

@implementation LRTVDBShowCell

- (void)awakeFromNib
{
    LRApplyCurlShadowToView(self.showImageView);
}

- (void)setShow:(LRTVDBShow *)show
{
    if (_show != show)
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
    self.showLabel.text = _show.name;
    self.episodeLabel.text = [self generateEpisodeLabelText];
    self.episodeDaysLabel.text = [self generateEpisodeDaysLabelText];

    [self.showImageView setImageWithURL:_show.posterURL
                       placeholderImage:[UIImage imageNamed:@"PosterPlaceholder"]
                         storageOptions:LRCacheStorageOptionsNSDictionary];
}

- (NSString *)generateEpisodeDaysLabelText
{
    if (self.show.episodes == nil) return kLoadingIndicator;
    
    NSNumber *daysToNextEpisode = self.show.daysToNextEpisode;
    
    switch (self.show.status)
    {
        case LRTVDBShowStatusEnded:
            return @"Show no longer airs";
            break;
            
        case LRTVDBShowStatusUpcoming:
            
            if ([daysToNextEpisode isEqualToNumber:@0])
            {
                return [NSString stringWithFormat:@"Next episode airs today"];
            }
            else if ([daysToNextEpisode isEqualToNumber:@1])
            {
                return [NSString stringWithFormat:@"Next episode airs tomorrow"];
            }
            else
            {
                return [NSString stringWithFormat:@"Next episode airs in %@ days", daysToNextEpisode];
            }
            break;
            
        case LRTVDBShowStatusTBA:
            return @"Next airdate to be announced";
            break;
            
        case LRTVDBShowStatusUnknown:
            return @"";
            break;
    }
}

- (NSString *)generateEpisodeLabelText
{
    if (self.show.episodes == nil) return kLoadingIndicator;
    
    LRTVDBEpisode *nextOrLastEpisode = self.show.nextEpisode ?: self.show.lastEpisode;
    
    if (nextOrLastEpisode)
    {
        return [NSString stringWithFormat:@"S%02dE%02d - %@",
                [nextOrLastEpisode.seasonNumber unsignedIntegerValue],
                [nextOrLastEpisode.episodeNumber unsignedIntegerValue],
                nextOrLastEpisode.title];
    }
    else
    {
        return @"No episodes information";
    }
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

@end
