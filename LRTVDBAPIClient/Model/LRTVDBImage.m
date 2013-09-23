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

// Persistence keys
static NSString *const kImageURLKey = @"kImageURLKey";
static NSString *const kImageThumbnailURLKey = @"kImageThumbnailURLKey";
static NSString *const kImageRatingKey = @"kImageRatingKey";
static NSString *const kImageRatingCountKey = @"kImageRatingCountKey";
static NSString *const kImageTypeKey = @"kImageTypeKey";

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

@interface LRTVDBImage ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *thumbnailURL;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSNumber *ratingCount;
@property (nonatomic) LRTVDBImageType type;

@end

@implementation LRTVDBImage

#pragma mark - Update image

- (void)updateWithImage:(LRTVDBImage *)updatedImage
{
    if (updatedImage == nil) return;
    
    NSAssert([self isEqual:updatedImage], @"Trying to update image with one with different url?");
    
    self.url = updatedImage.url;
    self.thumbnailURL = updatedImage.thumbnailURL;
    self.rating = updatedImage.rating;
    self.ratingCount = updatedImage.ratingCount;
    self.type = updatedImage.type;
}

#pragma mark - LRTVDBSerializableModelProtocol

+ (LRTVDBImage *)deserialize:(NSDictionary *)dictionary error:(NSError **)error
{
    LRTVDBImage *image = [[LRTVDBImage alloc] init];
        
    id url = LREmptyStringToNil(dictionary[kImageURLKey]);
    CHECK_NIL(url, @"url", *error);
    CHECK_TYPE(url, [NSString class], @"url", *error);
    image.url = [NSURL URLWithString:url];
    
    id thumbnailURL = LREmptyStringToNil(dictionary[kImageThumbnailURLKey]);
    CHECK_TYPE(thumbnailURL, [NSString class], @"thumbnailURL", *error);
    image.thumbnailURL = [NSURL URLWithString:thumbnailURL];
    
    id rating = LREmptyStringToNil(dictionary[kImageRatingKey]);
    CHECK_TYPE(rating, [NSNumber class], @"rating", *error);
    image.rating = rating;

    id ratingCount = LREmptyStringToNil(dictionary[kImageRatingCountKey]);
    CHECK_TYPE(ratingCount, [NSNumber class], @"ratingCount", *error);
    image.ratingCount = ratingCount;
    
    id imageType = LREmptyStringToNil(dictionary[kImageTypeKey]);
    CHECK_TYPE(imageType, [NSNumber class], @"imageType", *error);
    image.type = [imageType unsignedIntegerValue];
    
    return image;
}

- (NSDictionary *)serialize
{
    return @{ kImageURLKey : LRNilToEmptyString([self.url absoluteString]),
              kImageThumbnailURLKey : LRNilToEmptyString([self.thumbnailURL absoluteString]),
              kImageRatingKey : LRNilToEmptyString(self.rating),
              kImageRatingCountKey : LRNilToEmptyString(self.ratingCount),
              kImageTypeKey : @(self.type)
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
    return [NSString stringWithFormat:@"\nURL: %@\nThumbnail URL: %@\nRating: %@\nRating Count: %@\nType: %d\n",
            self.url, self.thumbnailURL, self.rating, self.ratingCount, self.type];
}

@end
