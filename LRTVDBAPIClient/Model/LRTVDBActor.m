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

// Persistence keys
static NSString *const kActorIDKey = @"kActorIDKey";
static NSString *const kActorNameKey = @"kActorNameKey";
static NSString *const kActorRoleKey = @"kActorRoleKey";
static NSString *const kActorImageURLKey = @"kActorImageURLKey";
static NSString *const kActorSortOrderKey = @"kActorSortOrderKey";

NSComparator LRTVDBActorComparator = ^NSComparisonResult(LRTVDBActor *firstActor, LRTVDBActor *secondActor)
{
    NSNumber *firstActorSortOrder = firstActor.sortOrder ? : @(NSIntegerMax);
    NSNumber *secondActorSortOrder = secondActor.sortOrder ? : @(NSIntegerMax);
    
    return [firstActorSortOrder compare:secondActorSortOrder];
};

@interface LRTVDBActor ()

@property (nonatomic, copy) NSString *actorID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *role;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSNumber *sortOrder;

@end

@implementation LRTVDBActor

#pragma mark - Update actor

- (void)updateWithActor:(LRTVDBActor *)updatedActor;
{
    if (updatedActor == nil) return;
    
    NSAssert([self isEqual:updatedActor], @"Trying to update actor with one with different ID?");
    
    self.actorID = updatedActor.actorID;
    self.name = updatedActor.name;
    self.role = updatedActor.role;
    self.imageURL = updatedActor.imageURL;
    self.sortOrder = updatedActor.sortOrder;
}

#pragma mark - LRTVDBSerializableModelProtocol

+ (LRTVDBActor *)deserialize:(NSDictionary *)dictionary error:(NSError **)error
{
    LRTVDBActor *actor = [[LRTVDBActor alloc] init];
    
    id actorId = LREmptyStringToNil(dictionary[kActorIDKey]);
    CHECK_NIL(actorId, @"actorId", *error);
    CHECK_TYPE(actorId, [NSString class], @"actorId", *error);
    actor.actorID = actorId;

    id actorName = LREmptyStringToNil(dictionary[kActorNameKey]);
    CHECK_NIL(actorName, @"actorName", *error);
    CHECK_TYPE(actorName, [NSString class], @"actorName", *error);
    actor.name = actorName;

    id actorRole = LREmptyStringToNil(dictionary[kActorRoleKey]);
    CHECK_TYPE(actorRole, [NSString class], @"actorRole", *error);
    actor.role = actorRole;
    
    id imageURL = LREmptyStringToNil(dictionary[kActorImageURLKey]);
    CHECK_TYPE(imageURL, [NSString class], @"imageURL", *error);
    actor.imageURL = [NSURL URLWithString:imageURL];

    id sortOrder = LREmptyStringToNil(dictionary[kActorSortOrderKey]);
    CHECK_TYPE(sortOrder, [NSNumber class], @"sortOrder", *error);
    actor.sortOrder = sortOrder;

    return actor;
}

- (NSDictionary *)serialize
{
    return @{ kActorIDKey : LRNilToEmptyString(self.actorID),
              kActorNameKey : LRNilToEmptyString(self.name),
              kActorRoleKey : LRNilToEmptyString(self.role),
              kActorImageURLKey : LRNilToEmptyString([self.imageURL absoluteString]),
              kActorSortOrderKey : LRNilToEmptyString(self.sortOrder)
            };
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
    return [NSString stringWithFormat:@"\nName: %@\nRole: %@\nImage: %@\nActor ID: %@\nSort order: %@\n",
            self.name, self.role, self.imageURL, self.actorID, self.sortOrder];
}

@end
