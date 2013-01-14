// LRTVDBImage.m
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

#import "LRTVDBImage.h"
#import "LRTVDBAPIClient+Private.h"

NSComparator LRTVDBImageComparator = ^NSComparisonResult(LRTVDBImage *firstImage, LRTVDBImage *secondImage)
{
    // Type: unknown image types at the end
    LRTVDBImageType firstImageType = firstImage.type;
    LRTVDBImageType secondImageType = secondImage.type;
    
    if (firstImageType == LRTVDBImageTypeUnknown) { firstImageType = NSIntegerMax; }
    if (secondImageType == LRTVDBImageTypeUnknown) { secondImageType = NSIntegerMax; }
    
    NSComparisonResult comparisonResult = [@(firstImageType) compare:@(secondImageType)];
    
    if (comparisonResult == NSOrderedSame)
    {
        // Rating
        NSNumber *firstImageRating = firstImage.rating ? : @(0);
        NSNumber *secondImageRating = secondImage.rating ? : @(0);
        comparisonResult = [secondImageRating compare:firstImageRating];
        
        if (comparisonResult == NSOrderedSame)
        {
            // Rating count
            NSNumber *firstImageRatingCount = firstImage.ratingCount ? : @(0);
            NSNumber *secondImageRatingCount = secondImage.ratingCount ? : @(0);
            comparisonResult = [secondImageRatingCount compare:firstImageRatingCount];
        }
    }
    
    return comparisonResult;
};

/**
 Image type XML strings.
 */
static NSString *const kLRTVDBImageTypeFanartKey = @"fanart";
static NSString *const kLRTVDBImageTypePosterKey = @"poster";
static NSString *const kLRTVDBImageTypeSeasonKey = @"season";
static NSString *const kLRTVDBImageTypeSeriesKey = @"series";

@interface LRTVDBImage ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *thumbnailURL;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSNumber *ratingCount;
@property (nonatomic) LRTVDBImageType type;

@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, copy) NSString *thumbnailURLString;
@property (nonatomic, copy) NSString *ratingString;
@property (nonatomic, copy) NSString *ratingCountString;
@property (nonatomic, copy) NSString *typeString;

@end

@implementation LRTVDBImage

#pragma mark - Initializer

+ (instancetype)imageWithDictionary:(NSDictionary *)dictionary
{
    return [self baseModelObjectWithDictionary:dictionary];
}

#pragma mark - Custom Setters

- (void)setUrlString:(NSString *)urlString
{
    _urlString = urlString;
    self.url = LRTVDBImageURLForPath(_urlString);
}

- (void)setThumbnailURLString:(NSString *)thumbnailURLString
{
    _thumbnailURLString = thumbnailURLString;
    self.thumbnailURL = LRTVDBImageURLForPath(_thumbnailURLString);
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
    
    if ([_typeString isEqualToString:kLRTVDBImageTypeFanartKey])
    {
        self.type = LRTVDBImageTypeFanart;
    }
    else if ([_typeString isEqualToString:kLRTVDBImageTypePosterKey])
    {
        self.type = LRTVDBImageTypePoster;
    }
    else if ([_typeString isEqualToString:kLRTVDBImageTypeSeasonKey])
    {
        self.type = LRTVDBImageTypeSeason;
    }
    else if ([_typeString isEqualToString:kLRTVDBImageTypeSeriesKey])
    {
        self.type = LRTVDBImageTypeBanner;
    }
    else
    {
        self.type = LRTVDBImageTypeUnknown;
    }
}

#pragma mark - LRBaseModelProtocol

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
    if (![object isKindOfClass:[LRTVDBImage class]])
    {
        return NO;
    }
    else
    {
        return [self.url isEqual:[(LRTVDBImage *)object url]];
    }
}

- (NSUInteger)hash
{
    return [self.url hash];
}

- (NSComparisonResult)compare:(id)object
{
    return LRTVDBImageComparator(self, object);
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"\nURL: %@\nThumbnail URL: %@\nRating: %@\nRating Count: %@\nType: %d\n", self.url, self.thumbnailURL, self.rating, self.ratingCount, self.type];
}

@end
