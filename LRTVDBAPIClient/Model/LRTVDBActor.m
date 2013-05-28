// LRTVDBActor.m
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

#import "LRTVDBActor.h"
#import "LRTVDBAPIClient+Private.h"
#import "LRTVDBBaseModel+Private.h"
#import "NSString+LRTVDBAdditions.h"

NSComparator LRTVDBActorComparator = ^NSComparisonResult(LRTVDBActor *firstActor, LRTVDBActor *secondActor)
{
    NSNumber *firstActorSortOrder = firstActor.sortOrder ? : @(NSIntegerMax);
    NSNumber *secondActorSortOrder = secondActor.sortOrder ? : @(NSIntegerMax);
    
    return [firstActorSortOrder compare:secondActorSortOrder];
};

@interface LRTVDBActor ()

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSNumber *sortOrder;

@end

@implementation LRTVDBActor

#pragma mark - Initializer

+ (instancetype)actorWithDictionary:(NSDictionary *)dictionary
{
    return [self tvdbBaseModelWithDictionary:dictionary];
}

#pragma mark - Custom Setters

- (void)setImageURLString:(NSString *)imageURLString
{
    self.imageURL = LRTVDBImageURLForPath(imageURLString);
}

- (void)setSortOrderString:(NSString *)sortOrderString
{
    self.sortOrder = @([sortOrderString integerValue]);
}

- (void)setName:(NSString *)name
{
    _name = [name unescapeHTMLEntities];
}

- (void)setRole:(NSString *)role
{
    _role = [role unescapeHTMLEntities];
}

#pragma mark - LRTVDBBaseModelMappingsProtocol

- (NSDictionary *)mappings
{
    return @{ @"Name" : @"name",
              @"Role": @"role",
              @"Image": @"imageURLString",
              @"SortOrder": @"sortOrderString",
              @"id" : @"actorID"
            };
}

#pragma mark - LRTVDBBaseModelSerializableProtocol

+ (LRTVDBActor *)deserialize:(NSDictionary *)dictionary
{
    return [self actorWithDictionary:dictionary];
}

- (NSDictionary *)serialize
{
    return self.persistenceDictionary;
}

#pragma mark - Equality methods

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[LRTVDBActor class]])
    {
        return NO;
    }
    else
    {
        return [self.actorID isEqualToString:[(LRTVDBActor *)object actorID]];
    }
}

- (NSUInteger)hash
{
    return [self.actorID hash];
}

- (NSComparisonResult)compare:(id)object
{
    return LRTVDBActorComparator(self, object);
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"\nName: %@\nRole: %@\nImage: %@\nActor ID: %@\nSort order: %@\n", self.name, self.role, self.imageURL, self.actorID, self.sortOrder];
}

@end
