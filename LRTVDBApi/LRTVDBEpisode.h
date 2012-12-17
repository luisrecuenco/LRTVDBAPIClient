// LRTVDBEpisode.h
//
// Copyright (c) 2012 Luis Recuenco
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

#import "LRKVCBaseModel.h"

extern NSComparisonResult (^LRTVDBEpisodeComparisonBlock)(id, id);

@class LRTVDBShow;

@interface LRTVDBEpisode : LRKVCBaseModel

@property (nonatomic, copy, readonly) NSString *episodeID;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSNumber *episodeNumber;
@property (nonatomic, strong, readonly) NSNumber *seasonNumber;
@property (nonatomic, strong, readonly) NSNumber *rating;
@property (nonatomic, strong, readonly) NSNumber *ratingCount;

/** Date in which the episode was aired. */
@property (nonatomic, strong, readonly) NSDate *airedDate;

/** Brief description of the episode. */
@property (nonatomic, copy, readonly) NSString *overview;

/** Example: http:/www.thetvdb.com/banners/episodes/82066/2948641.jpg. */
@property (nonatomic, strong, readonly) NSURL *artworkURL;

/** Example: http://www.imdb.com/title/imdbID (http://www.imdb.com/title/tt1635958/) */
@property (nonatomic, copy, readonly) NSString *imdbID;

@property (nonatomic, copy, readonly) NSString *language;
@property (nonatomic, copy, readonly) NSString *showID;

@property (nonatomic, copy, readonly) NSArray *writers;
@property (nonatomic, copy, readonly) NSArray *directors;
@property (nonatomic, copy, readonly) NSArray *guestStars;

@property (nonatomic, readonly, getter = hasAlreadyAired) BOOL alreadyAired;

@property (nonatomic, weak) LRTVDBShow *show;

/**
 Creates a new episode.
 @see LRKVCBaseModel initializer for more info.
 */
+ (instancetype)episodeWithDictionary:(NSDictionary *)dictionary;

@end
