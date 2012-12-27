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

NSComparator LRTVDBArtworkComparator = ^NSComparisonResult(LRTVDBArtwork *firstArtwork, LRTVDBArtwork *secondArtwork)
{
    // Type: unknown artwork types at the end
    LRTVDBArtworkType firstArtworkType = firstArtwork.type;
    LRTVDBArtworkType secondArtworkType = secondArtwork.type;
    
    if (firstArtworkType == LRTVDBArtworkTypeUnknown) { firstArtworkType = NSIntegerMax; }
    if (secondArtworkType == LRTVDBArtworkTypeUnknown) { secondArtworkType = NSIntegerMax; }
    
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

/**
 Artwork type XML strings.
 */
static NSString *const kLRTVDBArtworkTypeFanartKey = @"fanart";
static NSString *const kLRTVDBArtworkTypePosterKey = @"poster";
static NSString *const kLRTVDBArtworkTypeSeasonKey = @"season";
static NSString *const kLRTVDBArtworkTypeSeriesKey = @"series";

@interface LRTVDBArtwork ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *thumbnailURL;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSNumber *ratingCount;
@property (nonatomic) LRTVDBArtworkType type;

@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, copy) NSString *thumbnailURLString;
@property (nonatomic, copy) NSString *ratingString;
@property (nonatomic, copy) NSString *ratingCountString;
@property (nonatomic, copy) NSString *typeString;

@end

@implementation LRTVDBArtwork

#pragma mark - Initializer

+ (instancetype)artworkWithDictionary:(NSDictionary *)dictionary
{
    return [[self alloc] initWithDictionary:dictionary];
}

#pragma mark - Custom Setters

- (void)setUrlString:(NSString *)urlString
{
    _urlString = urlString;
    self.url = LRTVDBArtworkURLForPath(_urlString);
}

- (void)setThumbnailURLString:(NSString *)thumbnailURLString
{
    _thumbnailURLString = thumbnailURLString;
    self.thumbnailURL = LRTVDBArtworkURLForPath(_thumbnailURLString);
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

- (void)setTypeString:(NSString *)typeString
{
    _typeString = typeString;
    
    if ([_typeString isEqualToString:kLRTVDBArtworkTypeFanartKey])
    {
        self.type = LRTVDBArtworkTypeFanart;
    }
    else if ([_typeString isEqualToString:kLRTVDBArtworkTypePosterKey])
    {
        self.type = LRTVDBArtworkTypePoster;
    }
    else if ([_typeString isEqualToString:kLRTVDBArtworkTypeSeasonKey])
    {
        self.type = LRTVDBArtworkTypeSeason;
    }
    else if ([_typeString isEqualToString:kLRTVDBArtworkTypeSeriesKey])
    {
        self.type = LRTVDBArtworkTypeBanner;
    }
    else
    {
        self.type = LRTVDBArtworkTypeUnknown;
    }
}

#pragma mark - LRKVCBaseModelProtocol

- (NSDictionary *)mappings
{
    return @{ @"BannerPath" : @"urlString",
              @"ThumbnailPath": @"thumbnailURLString",
              @"Rating": @"ratingString",
              @"RatingCount": @"ratingCountString",
              @"BannerType" : @"typeString"
            };
}

#pragma mark - Equality methods

- (BOOL)isEqual:(id)object
{
    NSParameterAssert([object isKindOfClass:[LRTVDBArtwork class]]);
    
    if (![object isKindOfClass:[LRTVDBArtwork class]])
    {
        return NO;
    }
    else
    {
        return [self.url isEqual:[(LRTVDBArtwork *)object url]];
    }
}

- (NSUInteger)hash
{
    return [self.url hash];
}

- (NSComparisonResult)compare:(id)object
{
    return LRTVDBArtworkComparator(self, object);
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"\nURL: %@\nThumbnail URL: %@\nRating: %@\nRating Count: %@\nType: %d\n", self.url, self.thumbnailURL, self.rating, self.ratingCount, self.type];
}

@end
