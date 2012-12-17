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
#import "LRTVDBAPIClient.h"
#import "NSString+LRTVDBAdditions.h"
#import "NSArray+LRTVDBAdditions.h"

/**
 Episode comparison block.
 */
NSComparisonResult (^LRTVDBEpisodeComparisonBlock)(LRTVDBEpisode *, LRTVDBEpisode *) = ^NSComparisonResult(LRTVDBEpisode *firstEpisode, LRTVDBEpisode *secondEpisode)
{
    // It'd be easier to compare using LRTVDBEpisode airedDate property but
    // episodes that are yet to be aired are more likely to have season and
    // episode numbers rather than aired date...
    NSComparisonResult seasonNumberComparison = !secondEpisode.seasonNumber ? NSOrderedSame : [firstEpisode.seasonNumber compare:secondEpisode.seasonNumber];
    NSComparisonResult episodeNumberComparison = !secondEpisode.episodeNumber ?NSOrderedSame : [firstEpisode.episodeNumber compare:secondEpisode.episodeNumber];
    
    return seasonNumberComparison != NSOrderedSame ? seasonNumberComparison : episodeNumberComparison;
};

@interface LRTVDBEpisode ()

@property (nonatomic, copy) NSString *episodeID;
@property (nonatomic, copy) NSString *imdbID;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy) NSString *showID;

/**
 Making the following containers NSOrderedSet instead of simple NSArray
 has the only advantage of removing duplicates TVDB API may send.
 */
@property (nonatomic, copy) NSArray *writers;
@property (nonatomic, copy) NSArray *directors;
@property (nonatomic, copy) NSArray *guestStars;

@property (nonatomic, strong) NSNumber *episodeNumber;
@property (nonatomic, strong) NSNumber *seasonNumber;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSNumber *ratingCount;
@property (nonatomic, strong) NSURL *artworkURL;
@property (nonatomic, strong) NSDate *airedDate;

@property (nonatomic, copy) NSString *episodeNumberString;
@property (nonatomic, copy) NSString *seasonNumberString;
@property (nonatomic, copy) NSString *ratingString;
@property (nonatomic, copy) NSString *ratingCountString;
@property (nonatomic, copy) NSString *airedDateString;
@property (nonatomic, copy) NSString *artworkURLString;

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
    return [[self alloc] initWithDictionary:dictionary];
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
    _seasonNumberString = seasonNumberString;
    self.seasonNumber = @(_seasonNumberString.integerValue);
}

- (void)setEpisodeNumberString:(NSString *)episodeNumberString
{
    _episodeNumberString = episodeNumberString;
    self.episodeNumber = @(_episodeNumberString.integerValue);
}

- (void)setRatingString:(NSString *)ratingString
{
    _ratingString = ratingString;
    self.rating = @(_ratingString.floatValue);
}

- (void)setRatingCountString:(NSString *)ratingCountString
{
    _ratingCountString = ratingCountString;
    self.ratingCount = @(_ratingCountString.integerValue);
}

- (void)setAiredDateString:(NSString *)airedDateString
{
    _airedDateString = airedDateString;
    self.airedDate = _airedDateString.dateValue;
}

- (void)setArtworkURLString:(NSString *)artworkURLString
{
    _artworkURLString = artworkURLString;
    self.artworkURL = LRTVDBArtworkURLForPath(_artworkURLString);
}

- (void)setWritersList:(NSString *)writersList
{
    _writersList = writersList;
    self.writers = [[_writersList pipedStringToArray] arrayByRemovingDuplicates];
}

- (void)setDirectorsList:(NSString *)directorsList
{
    _directorsList = directorsList;
    self.directors = [[_directorsList pipedStringToArray] arrayByRemovingDuplicates];
}

- (void)setGuestStarsList:(NSString *)guestStarsList
{
    _guestStarsList = guestStarsList;
    self.guestStars = [[_guestStarsList pipedStringToArray] arrayByRemovingDuplicates];
}

#pragma mark - Update episode

- (void)updateWithEpisode:(LRTVDBEpisode *)updatedEpisode;
{
    NSAssert([self isEqual:updatedEpisode], @"Trying to update episode with one with different ID?");
    
    self.episodeID = updatedEpisode.episodeID;
    self.title = updatedEpisode.title;
    self.episodeNumberString = updatedEpisode.episodeNumberString;
    self.seasonNumberString = updatedEpisode.seasonNumberString;
    self.ratingString = updatedEpisode.ratingString;
    self.ratingCountString = updatedEpisode.ratingCountString;
    self.airedDateString = updatedEpisode.airedDateString;
    self.overview = updatedEpisode.overview;
    self.artworkURLString = updatedEpisode.artworkURLString;
    self.imdbID = updatedEpisode.imdbID;
    self.language = updatedEpisode.language;
    self.showID = updatedEpisode.showID;
    self.writersList = updatedEpisode.writersList;
    self.directorsList = updatedEpisode.directorsList;
    self.guestStarsList = updatedEpisode.guestStarsList;
}

#pragma mark - LRKVCBaseModelProtocol

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
              @"filename" : @"artworkURLString",
              @"IMDB_ID" : @"imdbID",
              @"Language" : @"language",
              @"seriesid" : @"showID",
              @"Writer" : @"writersList",
              @"Director" : @"directorsList",
              @"GuestStars" : @"guestStarsList"
            };
}

#pragma mark - Equality methods

- (BOOL)isEqual:(id)object
{
    return [self.episodeID isEqualToString:[(LRTVDBEpisode *)object episodeID]];
}

- (NSUInteger)hash
{
    return [self.episodeID hash];
}

- (NSComparisonResult)compare:(id)object
{
    return LRTVDBEpisodeComparisonBlock(self, object);
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"Title: %@\nSeason number: %@\nEpisode number: %@\nRating: %@\nOverview: %@\n", self.title, self.seasonNumber, self.episodeNumber, self.rating, self.overview];
}

@end
