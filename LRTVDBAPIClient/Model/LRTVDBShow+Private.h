// LRTVDBShow+Private.h
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

#import "LRTVDBShow.h"

/**
 Basic show status coming from the show XML.
 */
typedef NS_ENUM(NSInteger, LRTVDBShowBasicStatus)
{
    LRTVDBShowBasicStatusUnknown,
    LRTVDBShowBasicStatusContinuing,
    LRTVDBShowBasicStatusEnded,
};

@interface LRTVDBShow (Private)

@property (nonatomic, copy) NSString *showID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *overview;
@property (nonatomic, copy) NSString *imdbID;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy) NSString *airDay;
@property (nonatomic, copy) NSString *airTime;
@property (nonatomic, copy) NSString *contentRating;
@property (nonatomic, copy) NSString *network;
@property (nonatomic, strong) NSDate *premiereDate;
@property (nonatomic, strong) NSNumber *runtime;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSNumber *ratingCount;
@property (nonatomic, copy) NSArray *genres;
@property (nonatomic, copy) NSArray *actorsNames;
@property (nonatomic) LRTVDBShowBasicStatus basicStatus;

/**
 Methods to manage relationships.
 */
- (void)addEpisodes:(NSArray *)episodes;
- (void)addImages:(NSArray *)images;
- (void)addActors:(NSArray *)actors;

/**
 Updates a show.
 */
- (void)updateWithShow:(LRTVDBShow *)updatedShow
        updateEpisodes:(BOOL)updateEpisodes
          updateImages:(BOOL)updateImages
          updateActors:(BOOL)updateActors;

@end
