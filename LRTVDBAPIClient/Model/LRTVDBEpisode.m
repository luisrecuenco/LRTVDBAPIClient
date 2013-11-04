// LRTVDBEpisode.m
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

#import "LRTVDBEpisode.h"
#import "LRTVDBShow+Private.h"
#import "NSDate+LRTVDBAdditions.h"

// Persistence keys
static NSString *const kEpisodeIDKey = @"kEpisodeIDKey";
static NSString *const kEpisodeTitleKey = @"kEpisodeTitleKey";
static NSString *const kEpisodeOverviewKey = @"kEpisodeOverviewKey";
static NSString *const kEpisodeImageURLKey = @"kEpisodeImageURLKey";
static NSString *const kEpisodeAiredDateKey = @"kEpisodeAiredDateKey";
static NSString *const kEpisodeImdbIDKey = @"kEpisodeImdbIDKey";
static NSString *const kEpisodeDirectorsKey = @"kEpisodeDirectorsKey";
static NSString *const kEpisodeWritersKey = @"kEpisodeWritersKey";
static NSString *const kEpisodeGuestStarsKey = @"kEpisodeGuestStarsKey";
static NSString *const kEpisodeSeasonNumberKey = @"kEpisodeSeasonNumberKey";
static NSString *const kEpisodeNumberKey = @"kEpisodeNumberKey";
static NSString *const kEpisodeRatingKey = @"kEpisodeRatingKey";
static NSString *const kEpisodeRatingCountKey = @"kEpisodeRatingCountKey";
static NSString *const kEpisodeLanguageKey = @"kEpisodeLanguageKey";
static NSString *const kEpisodeShowIDKey = @"kEpisodeShowIDKey";
static NSString *const kEpisodeSeenKey = @"kEpisodeSeenKey";

const struct LRTVDBEpisodeAttributes LRTVDBEpisodeAttributes = {
    .seen = @"seen",
};

NSComparator LRTVDBEpisodeComparator = ^NSComparisonResult(LRTVDBEpisode *firstEpisode, LRTVDBEpisode *secondEpisode)
{
    // It'd be easier to compare using LRTVDBEpisode airedDate property but
    // episodes that are yet to be aired are more likely to have season and
    // episode numbers rather than aired date...
    
    NSNumber *firstEpisodeSeasonNumber = firstEpisode.seasonNumber ? : @(NSIntegerMax);
    NSNumber *secondEpisodeSeasonNumber = secondEpisode.seasonNumber ? : @(NSIntegerMax);
    
    NSComparisonResult comparisonResult = [firstEpisodeSeasonNumber compare:secondEpisodeSeasonNumber];
    
    if (comparisonResult == NSOrderedSame)
    {
        NSNumber *firstEpisodeEpisodeNumber = firstEpisode.episodeNumber ? : @(NSIntegerMax);
        NSNumber *secondEpisodeEpisodeNumber = secondEpisode.episodeNumber ? : @(NSIntegerMax);
        
        comparisonResult = [firstEpisodeEpisodeNumber compare:secondEpisodeEpisodeNumber];
    }
    
    return comparisonResult;
};

@interface LRTVDBEpisode ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *overview;
@property (nonatomic, copy) NSString *episodeID;
@property (nonatomic, copy) NSString *imdbID;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy) NSString *showID;
@property (nonatomic, copy) NSArray *writers;
@property (nonatomic, copy) NSArray *directors;
@property (nonatomic, copy) NSArray *guestStars;
@property (nonatomic, strong) NSNumber *episodeNumber;
@property (nonatomic, strong) NSNumber *seasonNumber;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSNumber *ratingCount;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSDate *airedDate;
@property (nonatomic, strong) NSNumber *numberOfDaysToAir;

@end

@implementation LRTVDBEpisode

- (void)setSeen:(BOOL)seen
{
    if (_seen != seen)
    {
        _seen = seen;
        
        [self.show seenStatusDidChangeForEpisode:self];
    }
}

- (void)setAiredDate:(NSDate *)airedDate
{
    if (_airedDate != airedDate)
    {
        _airedDate = airedDate;
        
        self.numberOfDaysToAir = [self daysToEpisode];
    }
}

- (NSNumber *)daysToEpisode
{
    if (_airedDate == nil) return @(NSIntegerMax);
    
    static NSCalendar *calendar = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = [NSCalendar currentCalendar];
    });
    
    // Timezones are really difficult to deal with. Ignoring time...
    NSDate *fromDate = [[NSDate date] dateByIgnoringTime];
    NSDate *toDate = [_airedDate dateByIgnoringTime];
    
    NSDateComponents *components = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate
                                                 toDate:toDate
                                                options:0];
    return @(components.day);
}

#pragma mark - Is Episode Special ?

- (BOOL)isSpecial
{
    return [self.seasonNumber isEqualToNumber:@(0)];
}

#pragma mark - Has episode already aired ?

- (BOOL)hasAlreadyAired
{
    return self.numberOfDaysToAir && [self.numberOfDaysToAir integerValue] <= 0;
}

#pragma mark - Is Episode correct?

- (BOOL)isCorrect
{
    return self.episodeID && self.title && self.seasonNumber &&
           [self.episodeNumber unsignedIntegerValue] > 0;
}

#pragma mark - IMDB URL

- (NSURL *)imdbURL
{
    if (!self.imdbID) return nil;
    
    return [NSURL URLWithString:[NSString stringWithFormat:
                                 @"http://www.imdb.com/title/%@/", self.imdbID]];
}

#pragma mark - Update episode

- (void)updateWithEpisode:(LRTVDBEpisode *)updatedEpisode;
{
    if (updatedEpisode == nil) return;
    
    NSAssert([self isEqual:updatedEpisode], @"Trying to update episode with one with different ID?");
    
    self.episodeID = updatedEpisode.episodeID;
    self.title = updatedEpisode.title;
    self.episodeNumber = updatedEpisode.episodeNumber;
    self.seasonNumber = updatedEpisode.seasonNumber;
    self.rating = updatedEpisode.rating;
    self.ratingCount = updatedEpisode.ratingCount;
    self.airedDate = updatedEpisode.airedDate;
    self.overview = updatedEpisode.overview;
    self.imageURL = updatedEpisode.imageURL;
    self.imdbID = updatedEpisode.imdbID;
    self.language = updatedEpisode.language;
    self.showID = updatedEpisode.showID;
    self.writers = updatedEpisode.writers;
    self.guestStars = updatedEpisode.guestStars;
    self.directors = updatedEpisode.directors;
}

#pragma mark - LRTVDBSerializableModelProtocol

+ (LRTVDBEpisode *)deserialize:(NSDictionary *)dictionary error:(NSError **)error
{    
    LRTVDBEpisode *episode = [[LRTVDBEpisode alloc] init];
    
    id episodeId = LREmptyStringToNil(dictionary[kEpisodeIDKey]);
    CHECK_NIL(episodeId, @"episodeId", *error);
    CHECK_TYPE(episodeId, [NSString class], @"episodeId", *error);
    episode.episodeID = episodeId;

    id title = LREmptyStringToNil(dictionary[kEpisodeTitleKey]);
    CHECK_NIL(title, @"title", *error);
    CHECK_TYPE(episodeId, [NSString class], @"title", *error);
    episode.title = title;

    id overview = LREmptyStringToNil(dictionary[kEpisodeOverviewKey]);
    CHECK_TYPE(overview, [NSString class], @"overview", *error);
    episode.overview = overview;

    id imageURL = LREmptyStringToNil(dictionary[kEpisodeImageURLKey]);
    CHECK_TYPE(imageURL, [NSString class], @"imageURL", *error);
    episode.imageURL = [NSURL URLWithString:imageURL];

    id airedDate = LREmptyStringToNil(dictionary[kEpisodeAiredDateKey]);
    CHECK_TYPE(airedDate, [NSDate class], @"airedDate", *error);
    episode.airedDate = airedDate;

    id imdbID = LREmptyStringToNil(dictionary[kEpisodeImdbIDKey]);
    CHECK_TYPE(imdbID, [NSString class], @"imdbID", *error);
    episode.imdbID = imdbID;

    id directors = LREmptyStringToNil(dictionary[kEpisodeDirectorsKey]);
    CHECK_TYPE(directors, [NSArray class], @"directors", *error);
    episode.directors = directors;

    id writers = LREmptyStringToNil(dictionary[kEpisodeWritersKey]);
    CHECK_TYPE(writers, [NSArray class], @"writers", *error);
    episode.writers = writers;

    id guestStars = LREmptyStringToNil(dictionary[kEpisodeGuestStarsKey]);
    CHECK_TYPE(guestStars, [NSArray class], @"guestStars", *error);
    episode.guestStars = guestStars;

    id seasonNumber = LREmptyStringToNil(dictionary[kEpisodeSeasonNumberKey]);
    CHECK_NIL(seasonNumber, @"seasonNumber", *error);
    CHECK_TYPE(seasonNumber, [NSNumber class], @"seasonNumber", *error);
    episode.seasonNumber = seasonNumber;

    id episodeNumber = LREmptyStringToNil(dictionary[kEpisodeNumberKey]);
    CHECK_NIL(episodeNumber, @"episodeNumber", *error);
    CHECK_TYPE(episodeNumber, [NSNumber class], @"episodeNumber", *error);
    episode.episodeNumber = episodeNumber;

    id rating = LREmptyStringToNil(dictionary[kEpisodeRatingKey]);
    CHECK_TYPE(rating, [NSNumber class], @"rating", *error);
    episode.rating = rating;

    id ratingCount = LREmptyStringToNil(dictionary[kEpisodeRatingCountKey]);
    CHECK_TYPE(ratingCount, [NSNumber class], @"ratingCount", *error);
    episode.ratingCount = ratingCount;

    id language = LREmptyStringToNil(dictionary[kEpisodeLanguageKey]);
    CHECK_TYPE(language, [NSString class], @"language", *error);
    episode.language = language;

    id showID = LREmptyStringToNil(dictionary[kEpisodeShowIDKey]);
    CHECK_NIL(showID, @"showID", *error);
    CHECK_TYPE(showID, [NSString class], @"showID", *error);
    episode.showID = showID;

    id seen = LREmptyStringToNil(dictionary[kEpisodeSeenKey]);
    CHECK_TYPE(seen, [NSNumber class], @"seen", *error);
    episode.seen = [seen boolValue];

    return episode;
}

- (NSDictionary *)serialize
{
    return @{ kEpisodeIDKey : LRNilToEmptyString(self.episodeID),
              kEpisodeTitleKey : LRNilToEmptyString(self.title),
              kEpisodeOverviewKey : LRNilToEmptyString(self.overview),
              kEpisodeImageURLKey : LRNilToEmptyString([self.imageURL absoluteString]),
              kEpisodeAiredDateKey : LRNilToEmptyString(self.airedDate),
              kEpisodeImdbIDKey : LRNilToEmptyString(self.imdbID),
              kEpisodeDirectorsKey : LRNilToEmptyString(self.directors),
              kEpisodeWritersKey : LRNilToEmptyString(self.writers),
              kEpisodeGuestStarsKey : LRNilToEmptyString(self.guestStars),
              kEpisodeSeasonNumberKey : LRNilToEmptyString(self.seasonNumber),
              kEpisodeNumberKey : LRNilToEmptyString(self.episodeNumber),
              kEpisodeRatingKey : LRNilToEmptyString(self.rating),
              kEpisodeRatingCountKey : LRNilToEmptyString(self.ratingCount),
              kEpisodeLanguageKey : LRNilToEmptyString(self.language),
              kEpisodeShowIDKey : LRNilToEmptyString(self.showID),
              kEpisodeSeenKey : @(self.seen)
            };    
}

#pragma mark - Equality methods

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[LRTVDBEpisode class]])
    {
        return NO;
    }
    else
    {
        return [self.episodeID isEqualToString:[(LRTVDBEpisode *)object episodeID]];
    }
}

- (NSUInteger)hash
{
    return [self.episodeID hash];
}

- (NSComparisonResult)compare:(id)object
{
    return LRTVDBEpisodeComparator(self, object);
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"Title: %@\nSeason number: %@\nEpisode number: %@\nRating: %@\nOverview: %@\n",
            self.title, self.seasonNumber, self.episodeNumber, self.rating, self.overview];
}

@end
