// LRTVDBArtwork.m
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

#import "LRTVDBArtwork.h"
#import "LRTVDBAPIClient.h"

/**
 Artwork comparison block.
 */
NSComparator LRTVDBArtworkComparator = ^NSComparisonResult(LRTVDBArtwork *firstArtwork, LRTVDBArtwork *secondArtwork)
{
    // Type: unknown artwork types at the end
    LRTVDBArtworkType firstArtworkType = firstArtwork.artworkType;
    LRTVDBArtworkType secondArtworkType = secondArtwork.artworkType;
    
    if (firstArtworkType == LRTVDBArtworkTypeUnknown) { firstArtworkType = INT_MAX; }
    if (secondArtworkType == LRTVDBArtworkTypeUnknown) { secondArtworkType = INT_MAX; }
    
    NSComparisonResult comparisonResult = [@(firstArtworkType) compare:@(secondArtworkType)];
    
    if (comparisonResult == NSOrderedSame)
    {
        // Rating
        NSNumber *firstArtworkRating = firstArtwork.rating ? : @(0);
        NSNumber *secondArtworkRating = secondArtwork.rating ? : @(0);
        comparisonResult = [secondArtworkRating compare:firstArtworkRating];
        
        if (comparisonResult == NSOrderedSame)
        {
            // Rating count
            NSNumber *firstArtworkRatingCount = firstArtwork.ratingCount ? : @(0);
            NSNumber *secondArtworkRatingCount = secondArtwork.ratingCount ? : @(0);
            comparisonResult = [secondArtworkRatingCount compare:firstArtworkRatingCount];
        }
    }
    
    return comparisonResult;
};

static NSString *const kLRTVDBArtworkTypeFanartKey = @"fanart";
static NSString *const kLRTVDBArtworkTypePosterKey = @"poster";
static NSString *const kLRTVDBArtworkTypeSeasonKey = @"season";
static NSString *const kLRTVDBArtworkTypeSeriesKey = @"series";

@interface LRTVDBArtwork ()

@property (nonatomic, strong) NSURL *artworkURL;
@property (nonatomic, strong) NSURL *artworkThumbnailURL;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSNumber *ratingCount;
@property (nonatomic) LRTVDBArtworkType artworkType;

@property (nonatomic, copy) NSString *artworkURLString;
@property (nonatomic, copy) NSString *artworkThumbnailURLString;
@property (nonatomic, copy) NSString *ratingString;
@property (nonatomic, copy) NSString *ratingCountString;
@property (nonatomic, copy) NSString *artworkTypeString;

@end

@implementation LRTVDBArtwork

#pragma mark - Initializer

+ (instancetype)artworkWithDictionary:(NSDictionary *)dictionary
{
    return [[self alloc] initWithDictionary:dictionary];
}

#pragma mark - Custom Setters

- (void)setArtworkURLString:(NSString *)artworkURLString
{
    _artworkURLString = artworkURLString;
    self.artworkURL = LRTVDBArtworkURLForPath(_artworkURLString);
}

- (void)setArtworkThumbnailURLString:(NSString *)artworkThumbnailURLString
{
    _artworkThumbnailURLString = artworkThumbnailURLString;
    self.artworkThumbnailURL = LRTVDBArtworkURLForPath(_artworkThumbnailURLString);
}

- (void)setRatingString:(NSString *)ratingString
{
    _ratingString = ratingString;
    self.rating = @(_ratingString.floatValue);
}

- (void)setRatingCountString:(NSString *)ratingCountString
{
    _ratingCountString = ratingCountString;
    self.ratingCount =  @(_ratingCountString.integerValue);
}

- (void)setArtworkTypeString:(NSString *)artworkTypeString
{
    _artworkTypeString = artworkTypeString;
    
    if ([_artworkTypeString isEqualToString:kLRTVDBArtworkTypeFanartKey])
    {
        self.artworkType = LRTVDBArtworkTypeFanart;
    }
    else if ([_artworkTypeString isEqualToString:kLRTVDBArtworkTypePosterKey])
    {
        self.artworkType = LRTVDBArtworkTypePoster;
    }
    else if ([_artworkTypeString isEqualToString:kLRTVDBArtworkTypeSeasonKey])
    {
        self.artworkType = LRTVDBArtworkTypeSeason;
    }
    else if ([_artworkTypeString isEqualToString:kLRTVDBArtworkTypeSeriesKey])
    {
        self.artworkType = LRTVDBArtworkTypeBanner;
    }
    else
    {
        self.artworkType = LRTVDBArtworkTypeUnknown;
    }
}

#pragma mark - LRKVCBaseModelProtocol

- (NSDictionary *)mappings
{
    return @{ @"BannerPath" : @"artworkURLString",
              @"ThumbnailPath": @"artworkThumbnailURLString",
              @"Rating": @"ratingString",
              @"RatingCount": @"ratingCountString",
              @"BannerType" : @"artworkTypeString"
            };
}

#pragma mark - Equality methods

- (BOOL)isEqual:(id)object
{
    return [self.artworkURL isEqual:[(LRTVDBArtwork *)object artworkURL]];
}

- (NSUInteger)hash
{
    return [self.artworkURL hash];
}

- (NSComparisonResult)compare:(id)object
{
    return LRTVDBArtworkComparator(self, object);
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"\nURL: %@\nThumbnail URL: %@\nRating: %@\nRating Count: %@\nType: %d\n", self.artworkURL, self.artworkThumbnailURL, self.rating, self.ratingCount, self.artworkType];
}

@end
