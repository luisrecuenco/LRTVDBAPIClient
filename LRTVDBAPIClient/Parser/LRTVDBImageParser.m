// LRTVDBImageParser.m
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

#import "LRTVDBAPIClient+Private.h"
#import "LRTVDBImage+Private.h"
#import "LRTVDBImageParser.h"
#import "TBXML.h"

// XML keys
static NSString *const kLRTVDBImageSiblingXMLKey = @"Banner";
static NSString *const kLRTVDBImageUrlXMLKey = @"BannerPath";
static NSString *const kLRTVDBImageUrlThumbnailXMLKey = @"ThumbnailPath";
static NSString *const kLRTVDBImageRatingXMLKey = @"Rating";
static NSString *const kLRTVDBImageRatingCountXMLKey = @"RatingCount";
static NSString *const kLRTVDBImageTypeXMLKey = @"BannerType";
static NSString *const kLRTVDBImageTypeFanartXMLKey = @"fanart";
static NSString *const kLRTVDBImageTypePosterXMLKey = @"poster";
static NSString *const kLRTVDBImageTypeSeasonXMLKey = @"season";
static NSString *const kLRTVDBImageTypeSeriesXMLKey = @"series";

@implementation LRTVDBImageParser

+ (instancetype)parser
{
    return [[self alloc] init];
}

- (NSArray *)imagesFromData:(NSData *)data
{
    NSError *error = nil;
    TBXML *tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
    TBXMLElement *root = tbxml.rootXMLElement;
    
    if (error || !root) return nil;
        
    TBXMLElement *imageElement = [TBXML childElementNamed:kLRTVDBImageSiblingXMLKey parentElement:root];
    
    NSMutableArray *images = [NSMutableArray array];
    
    while (imageElement != nil)
    {
        LRTVDBImage *image = [[LRTVDBImage alloc] init];
        
        TBXMLElement *imageUrlElement = [TBXML childElementNamed:kLRTVDBImageUrlXMLKey parentElement:imageElement];
        TBXMLElement *imageThumbnailUrlElement = [TBXML childElementNamed:kLRTVDBImageUrlThumbnailXMLKey parentElement:imageElement];
        TBXMLElement *imageRatingElement = [TBXML childElementNamed:kLRTVDBImageRatingXMLKey parentElement:imageElement];
        TBXMLElement *imageRatingCountElement = [TBXML childElementNamed:kLRTVDBImageRatingCountXMLKey parentElement:imageElement];
        TBXMLElement *imageTypeElement = [TBXML childElementNamed:kLRTVDBImageTypeXMLKey parentElement:imageElement];
        
        if (imageUrlElement) image.url = LRTVDBImageURLForPath(LREmptyStringToNil([TBXML textForElement:imageUrlElement]));
        if (imageThumbnailUrlElement) image.thumbnailURL = LRTVDBImageURLForPath(LREmptyStringToNil([TBXML textForElement:imageThumbnailUrlElement]));
        if (imageRatingElement) image.rating = @([LREmptyStringToNil([TBXML textForElement:imageRatingElement]) floatValue]);
        if (imageRatingCountElement) image.ratingCount = @([LREmptyStringToNil([TBXML textForElement:imageRatingCountElement]) integerValue]);
        
        if (imageTypeElement)
        {
            NSString *imageTypeString = LREmptyStringToNil([TBXML textForElement:imageTypeElement]);
            
            if ([imageTypeString isEqualToString:kLRTVDBImageTypeFanartXMLKey])
            {
                image.type = LRTVDBImageTypeFanart;
            }
            else if ([imageTypeString isEqualToString:kLRTVDBImageTypePosterXMLKey])
            {
                image.type = LRTVDBImageTypePoster;
            }
            else if ([imageTypeString isEqualToString:kLRTVDBImageTypeSeasonXMLKey])
            {
                image.type = LRTVDBImageTypeSeason;
            }
            else if ([imageTypeString isEqualToString:kLRTVDBImageTypeSeriesXMLKey])
            {
                image.type = LRTVDBImageTypeBanner;
            }
        }
        
        [images addObject:image];
        
        imageElement = [TBXML nextSiblingNamed:kLRTVDBImageSiblingXMLKey searchFromElement:imageElement];
    }
    
    return [images copy];
}

@end
