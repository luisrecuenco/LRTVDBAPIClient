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
#import "LRTVDBAPIClient+Private.h"
#import "NSString+LRTVDBAdditions.h"
#import "NSArray+LRTVDBAdditions.h"
#import "LRTVDBBaseModel+Private.h"
#import "LRTVDBShow.h"

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

/** Writer 1|Writer 2... */
@property (nonatomic, copy) NSString *writersList;

/** Director 1|Director 2... */
@property (nonatomic, copy) NSString *directorsList;

/** Guest Star 1|Guest Star 2... */
@property (nonatomic, copy) NSString *guestStarsList;

@end

@implementation LRTVDBEpisode

#pragma mark - Initializer

+ (instancetype)episodeWithDictionary:(NSDictionary *)dictionary
{
    return [self tvdbBaseModelWithDictionary:dictionary];
}

#pragma mark - Has episode already aired ?

- (BOOL)hasAlreadyAired
{
    return [self compare:self.show.lastEpisode] <= NSOrderedSame;
}

#pragma mark - Has episode been seen?

- (BOOL)hasBeenSeen
{
   return self.show.lastEpisodeSeen &&
          [self.show.lastEpisodeSeen compare:self] >= NSOrderedSame;
}

#pragma mark - Is Episode correct?

- (BOOL)isCorrect
{
    return self.episodeID && self.title && self.seasonNumber && self.episodeNumber.unsignedIntegerValue > 0;
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
    self.writersList = updatedEpisode.writersList;
    self.directorsList = updatedEpisode.directorsList;
    self.guestStarsList = updatedEpisode.guestStarsList;
    self.persistenceDictionary = updatedEpisode.persistenceDictionary;
}

#pragma mark - Custom Setters

- (void)setTitle:(NSString *)title
{
    _title = [title unescapeHTMLEntities];
}

- (void)setOverview:(NSString *)overview
{
    _overview = [overview unescapeHTMLEntities];
}

- (void)setSeasonNumberString:(NSString *)seasonNumberString
{
    self.seasonNumber = @([seasonNumberString integerValue]);
}

- (void)setEpisodeNumberString:(NSString *)episodeNumberString
{
    self.episodeNumber = @([episodeNumberString integerValue]);
}

- (void)setRatingString:(NSString *)ratingString
{
    self.rating = @([ratingString floatValue]);
}

- (void)setRatingCountString:(NSString *)ratingCountString
{
    self.ratingCount = @([ratingCountString integerValue]);
}

- (void)setAiredDateString:(NSString *)airedDateString
{
    self.airedDate = [airedDateString dateValue];
}

- (void)setImageURLString:(NSString *)imageURLString
{
    self.imageURL = LRTVDBImageURLForPath(imageURLString);
}

- (void)setWritersList:(NSString *)writersList
{
    self.writers = [[writersList pipedStringToArray] arrayByRemovingDuplicates];
}

- (void)setDirectorsList:(NSString *)directorsList
{
    self.directors = [[directorsList pipedStringToArray] arrayByRemovingDuplicates];
}

- (void)setGuestStarsList:(NSString *)guestStarsList
{
    self.guestStars = [[guestStarsList pipedStringToArray] arrayByRemovingDuplicates];
}

#pragma mark - LRTVDBBaseModelMappingsProtocol

- (NSDictionary *)mappings
{
    return @{ @"id" : @"episodeID",
              @"EpisodeName" : @"title",
              @"EpisodeNumber": @"episodeNumberString",
              @"SeasonNumber": @"seasonNumberString",
              @"Rating": @"ratingString",
              @"RatingCount" : @"ratingCountString",
              @"FirstAired" : @"airedDateString",
              @"Overview" : @"overview",
              @"filename" : @"imageURLString",
              @"IMDB_ID" : @"imdbID",
              @"Language" : @"language",
              @"seriesid" : @"showID",
              @"Writer" : @"writersList",
              @"Director" : @"directorsList",
              @"GuestStars" : @"guestStarsList"
            };
}

#pragma mark - LRTVDBBaseModelSerializableProtocol

+ (LRTVDBEpisode *)deserialize:(NSDictionary *)dictionary
{
    return [self episodeWithDictionary:dictionary];
}

- (NSDictionary *)serialize
{
    return self.persistenceDictionary;
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
    return [NSString stringWithFormat:@"Title: %@\nSeason number: %@\nEpisode number: %@\nRating: %@\nOverview: %@\n", self.title, self.seasonNumber, self.episodeNumber, self.rating, self.overview];
}

@end
