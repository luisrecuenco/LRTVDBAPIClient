// LRTVDBEpisodeCell.m
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

#import "LRTVDBEpisodeCell.h"
#import "LRTVDBShow.h"
#import "LRTVDBEpisode.h"
#import "LRSwitchButton.h"

#define LAST_EPISODE_MARKER_COLOR [UIColor colorWithRed:0.36f green:0.47f blue:0.59f alpha:1.0f].CGColor

NSString *const LRTVDBEpisodeCellReuseIdentifier = @"LRTVDBEpisodeCellReuseIdentifier";

static CGFloat const kLastEpisodeMarkerLineWidth = 3.0f;

@interface LRTVDBEpisodeCell ()

@property (nonatomic, strong) LRTVDBEpisode *episode;

@property (nonatomic, strong) CAShapeLayer *lastEpisodeIndicatorLayer;
@property (nonatomic, assign) CGRect originalDateFrame;

@end

@implementation LRTVDBEpisodeCell

- (void)awakeFromNib
{
    self.lastEpisodeIndicatorLayer = [CAShapeLayer layer];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, self.frame.size.height - kLastEpisodeMarkerLineWidth/2)];
    [path addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height - kLastEpisodeMarkerLineWidth/2)];
    
    self.lastEpisodeIndicatorLayer.strokeColor = LAST_EPISODE_MARKER_COLOR;
    self.lastEpisodeIndicatorLayer.lineWidth = kLastEpisodeMarkerLineWidth;
    self.lastEpisodeIndicatorLayer.path = path.CGPath;
    [self.layer addSublayer:self.lastEpisodeIndicatorLayer];
    
    self.originalDateFrame = self.dateLabel.frame;
}

- (void)setEpisode:(LRTVDBEpisode *)episode
{
    _episode = episode;
    
    self.nameLabel.text = [NSString stringWithFormat:@"%@ - %@", episode.episodeNumber, episode.title];
    
    self.dateLabel.frame = [self computeDateLabelFrame];
    
    self.nameLabel.textColor = episode.hasAlreadyAired ?
                               [UIColor blackColor] :
                               [UIColor grayColor];
    
    self.dateLabel.text = [NSDateFormatter localizedStringFromDate:episode.airedDate
                                                         dateStyle:NSDateFormatterLongStyle
                                                         timeStyle:NSDateFormatterNoStyle];
    
    self.lastEpisodeIndicatorLayer.hidden = episode != episode.show.lastEpisode;
    self.episodeSeenButton.hidden = ![episode hasAlreadyAired];
    self.episodeSeenButton.filled = [episode hasBeenSeen];
}

- (CGRect)computeDateLabelFrame
{
    NSString *substring = [self.nameLabel.text substringToIndex:
                           [self.nameLabel.text rangeOfString:_episode.title].location];
    
    CGSize textSize = [substring sizeWithFont:self.nameLabel.font];
    
    CGRect dateFrame = self.originalDateFrame;
    dateFrame.size.width -= textSize.width;
    dateFrame.origin.x += textSize.width;
    
    return dateFrame;
}

- (IBAction)episodeSeenButtonTapped:(id)sender
{
    [self.delegate episodeSeenButtonTappedOnCell:self];
}

@end
