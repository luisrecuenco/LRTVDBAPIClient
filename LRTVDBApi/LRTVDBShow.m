// LRTVDBShow.m
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

#import "LRTVDBShow.h"
#import "LRTVDBEpisode.h"
#import "LRTVDBArtwork.h"
#import "LRTVDBActor.h"
#import "NSDate+LRTVDBAdditions.h"
#import "NSString+LRTVDBAdditions.h"
#import "LRTVDBAPIClient.h"

/**
 Status XML dictionary keys.
 */
static NSString *const kLRTVDBShowBasicStatusContinuingKey = @"Continuing";
static NSString *const kLRTVDBShowBasicStatusEndedKey = @"Ended";

/**
 Basic show status coming from the show XML.
 */
typedef NS_ENUM(NSInteger, LRTVDBShowBasicStatus)
{
    LRTVDBShowBasicStatusUnknown,
    LRTVDBShowBasicStatusContinuing,
    LRTVDBShowBasicStatusEnded,
};

/**
 Episodes comparison block.
 */
static NSComparisonResult (^episodesComparisonBlock)(LRTVDBEpisode *, LRTVDBEpisode *) = ^NSComparisonResult(LRTVDBEpisode *firstEpisode, LRTVDBEpisode *secondEpisode)
{
    // It'd be easier to compare using LRTVDBEpisode airedDate property but
    // episodes that are yet to be aired are more likely to have season and
    // episode numbers rather than aired date...
    NSComparisonResult seasonNumberComparison = [firstEpisode.seasonNumber compare:secondEpisode.seasonNumber];
    NSComparisonResult episodeNumberComparison = [firstEpisode.episodeNumber compare:secondEpisode.episodeNumber];
    
    return seasonNumberComparison != NSOrderedSame ? seasonNumberComparison : episodeNumberComparison;
};

/**
 Artwork comparison block.
 */
static NSComparisonResult (^artworkComparisonBlock)(LRTVDBArtwork *, LRTVDBArtwork *) = ^NSComparisonResult(LRTVDBArtwork *firstArtwork, LRTVDBArtwork *secondArtwork)
{
    NSComparisonResult typeComparison = [@(firstArtwork.artworkType) compare:@(secondArtwork.artworkType)];
    NSComparisonResult ratingComparison = [secondArtwork.rating compare:firstArtwork.rating];
    NSComparisonResult ratingCountComparison = [secondArtwork.ratingCount compare:firstArtwork.ratingCount];
    
    if (typeComparison != NSOrderedSame)
    {
        return typeComparison;
    }
    else if (ratingComparison != NSOrderedSame)
    {
        return ratingComparison;
    }
    else
    {
        return ratingCountComparison;
    }
};

/**
 Actors comparison block.
 */
static NSComparisonResult (^actorsComparisonBlock)(LRTVDBActor *, LRTVDBActor*) = ^NSComparisonResult(LRTVDBActor *firstActor, LRTVDBActor *secondActor)
{
    return [firstActor.sortOrder compare:secondActor.sortOrder];
};

@interface LRTVDBShow ()

@property (nonatomic, copy) NSString *showID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *overview;
@property (nonatomic, copy) NSString *imdbID;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy) NSString *airDay;
@property (nonatomic, copy) NSString *airTime;
@property (nonatomic, copy) NSString *contentRating;
@property (nonatomic, copy) NSString *genres;
@property (nonatomic, copy) NSString *actorsNames;
@property (nonatomic, copy) NSString *network;
@property (nonatomic, copy) NSString *runtime;
@property (nonatomic, strong) NSDate *premiereDate;
@property (nonatomic, strong) NSURL *bannerURL;
@property (nonatomic, strong) NSURL *fanartURL;
@property (nonatomic, strong) NSURL *posterURL;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSNumber *ratingCount;
@property (nonatomic) LRTVDBShowStatus showStatus;
@property (nonatomic) LRTVDBShowBasicStatus showBasicStatus;

@property (nonatomic, strong) NSOrderedSet *episodes;
@property (nonatomic, strong) LRTVDBEpisode *lastEpisode;
@property (nonatomic, strong) LRTVDBEpisode *nextEpisode;
@property (nonatomic, strong) NSNumber *daysToNextEpisode;
@property (nonatomic, strong) NSNumber *numberOfSeasons;

@property (nonatomic, strong) NSOrderedSet *artworks;
@property (nonatomic, strong) NSArray *fanartArtworks;
@property (nonatomic, strong) NSArray *posterArtworks;
@property (nonatomic, strong) NSArray *seasonArtworks;
@property (nonatomic, strong) NSArray *bannerArtworks;

@property (nonatomic, strong) NSOrderedSet *actors;

@property (nonatomic, copy) NSString *bannerURLString;
@property (nonatomic, copy) NSString *posterURLString;
@property (nonatomic, copy) NSString *fanartURLString;

@property (nonatomic, copy) NSString *ratingString;
@property (nonatomic, copy) NSString *ratingCountString;
@property (nonatomic, copy) NSString *showStatusString;
@property (nonatomic, copy) NSString *premiereDateString;

@property (nonatomic, strong) NSMutableOrderedSet *mutableEpisodes;
@property (nonatomic, strong) NSMutableOrderedSet *mutableArtworks;
@property (nonatomic, strong) NSMutableOrderedSet *mutableActors;

@property (nonatomic, strong) NSMutableDictionary *seasonToEpisodesDictionary;

@end

@implementation LRTVDBShow

#pragma mark - Custom Setters

- (void)setName:(NSString *)name
{
    _name = [name unescapeHTMLEntities];
}

- (void)setOverview:(NSString *)overview
{
    _overview = [overview unescapeHTMLEntities];
}

- (void)setPremiereDateString:(NSString *)premiereDateString
{
    _premiereDateString = premiereDateString;
    self.premiereDate = _premiereDateString.dateValue;
}

- (void)setBannerURLString:(NSString *)bannerURLString
{
    _bannerURLString = bannerURLString;
    self.bannerURL = LRTVDBArtworkURLForPath(_bannerURLString);
}

- (void)setFanartURLString:(NSString *)fanartURLString
{
    _fanartURLString = fanartURLString;
    self.fanartURL = LRTVDBArtworkURLForPath(_fanartURLString);
}

- (void)setPosterURLString:(NSString *)posterURLString
{
    _posterURLString = posterURLString;
    self.posterURL = LRTVDBArtworkURLForPath(_posterURLString);
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

- (void)setShowStatusString:(NSString *)showStatusString
{
    _showStatusString = showStatusString;
    
    if ([_showStatusString isEqualToString:kLRTVDBShowBasicStatusContinuingKey])
    {
        self.showBasicStatus = LRTVDBShowBasicStatusContinuing;
    }
    else if ([_showStatusString isEqualToString:kLRTVDBShowBasicStatusEndedKey])
    {
        self.showBasicStatus = LRTVDBShowStatusEnded;
    }
    else
    {
        self.showBasicStatus = LRTVDBShowStatusUnknown;
    }
}

#pragma mark - Episodes handling

- (void)addEpisodes:(NSArray *)episodes
{
    if (self.mutableEpisodes == nil)
    {
        self.mutableEpisodes = [NSMutableOrderedSet orderedSet];
    }
    
    // Assumption: episodes are newer than the ones we may already have.
    NSMutableOrderedSet *updatedEpisodes = [NSMutableOrderedSet orderedSetWithArray:episodes];
    [updatedEpisodes unionOrderedSet:self.mutableEpisodes];
    [updatedEpisodes sortUsingComparator:episodesComparisonBlock];
    
    self.mutableEpisodes = [updatedEpisodes copy];
    self.episodes = [self.mutableEpisodes copy];
    
    [self refreshEpisodesInfomation];
}

- (void)refreshEpisodesInfomation
{
    self.seasonToEpisodesDictionary = nil; // Regenerate
    __block BOOL lastEpisodeSet = NO;
    
    // Last episode
    if (self.showBasicStatus == LRTVDBShowBasicStatusEnded)
    {
        self.lastEpisode = self.mutableEpisodes.lastObject;
        lastEpisodeSet = YES;
    }
    else
    {
        NSDate *fromDate = [[NSDate date] dateByIgnoringTime];
        
        void (^block)(LRTVDBEpisode *, NSUInteger, BOOL *) = ^(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop)
        {
            NSDate *toDate = episode.airedDate;
            
            if ([toDate compare:fromDate] == NSOrderedAscending)
            {
                self.lastEpisode = episode;
                lastEpisodeSet = YES;
                *stop = YES;
            }
        };
        
        [self.mutableEpisodes enumerateObjectsWithOptions:NSEnumerationReverse
                                               usingBlock:block];
        
        if (!lastEpisodeSet)
        {
            self.lastEpisode = self.mutableEpisodes.lastObject;
        }
    }
    
    // Next episode
    NSUInteger nextEpisodeIndex = [self.mutableEpisodes indexOfObject:self.lastEpisode] + 1;
    BOOL notValidNextEpisode = nextEpisodeIndex >= self.mutableEpisodes.count ||
                               [(self.mutableEpisodes)[nextEpisodeIndex] airedDate] == nil;
    self.nextEpisode = notValidNextEpisode ? nil : (self.mutableEpisodes)[nextEpisodeIndex];
    
    // Days to next episode
    self.daysToNextEpisode = [self daysToEpisode:self.nextEpisode];
    
    // Number of seasons
    self.numberOfSeasons = [self.mutableEpisodes.lastObject seasonNumber];
    
    // Show status
    if (self.showBasicStatus == LRTVDBShowStatusEnded)
    {
        self.showStatus = LRTVDBShowStatusEnded;
    }
    else if (self.showBasicStatus == LRTVDBShowBasicStatusContinuing)
    {
        self.showStatus =  [self.daysToNextEpisode isEqualToNumber:@(NSNotFound)] ?
        LRTVDBShowStatusTBA : LRTVDBShowStatusUpcoming;
    }
    else
    {
        self.showStatus = LRTVDBShowStatusUnknown;
    }
}

- (NSNumber *)daysToEpisode:(LRTVDBEpisode *)episode
{
    if (episode.airedDate == nil) return @(NSNotFound);
    
    static NSCalendar *calendar = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = [NSCalendar currentCalendar];
    });
    
    // Timezones are really difficult to deal with. Ignoring time...
    NSDate *fromDate = [[NSDate date] dateByIgnoringTime];
    NSDate *toDate = episode.airedDate;
    
    NSDateComponents *components = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate
                                                 toDate:toDate
                                                options:0];
    return @(components.day);
}

- (NSArray *)episodesForSeason:(NSNumber *)seasonNumber
{
    if (self.seasonToEpisodesDictionary == nil)
    {
        self.seasonToEpisodesDictionary = [@{} mutableCopy];
    }
    
    NSArray *episodes = (self.seasonToEpisodesDictionary)[seasonNumber];
    
    if (!episodes)
    {
        NSIndexSet *indexSet = [self.mutableEpisodes indexesOfObjectsPassingTest:^BOOL(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop)
        {
            return [episode.seasonNumber isEqualToNumber:seasonNumber];
        }];
        
        episodes = [self.mutableEpisodes objectsAtIndexes:indexSet];
        
        (self.seasonToEpisodesDictionary)[seasonNumber] = episodes;
    }
    
    return episodes;
}

#pragma mark - Artwork handling

- (void)addArtworks:(NSArray *)artworks
{
    if (self.mutableArtworks == nil)
    {
        self.mutableArtworks = [NSMutableOrderedSet orderedSet];
    }
    
    // Assumption: artworks are newer than the ones we may already have.
    NSMutableOrderedSet *updatedArtworks = [NSMutableOrderedSet orderedSetWithArray:artworks];
    [updatedArtworks unionOrderedSet:self.mutableArtworks];
    [updatedArtworks sortUsingComparator:artworkComparisonBlock];
    
    self.mutableArtworks = [updatedArtworks copy];
    self.artworks = [self.mutableArtworks copy];
    
    [self computeArtworkInfomation];
}

- (void)computeArtworkInfomation
{
    NSMutableArray *fanartArray = [@[] mutableCopy];
    NSMutableArray *posterArray = [@[] mutableCopy];
    NSMutableArray *seasonArray = [@[] mutableCopy];
    NSMutableArray *bannerArray = [@[] mutableCopy];
    
    for (LRTVDBArtwork *artwork in self.mutableArtworks)
    {
        switch (artwork.artworkType)
        {
            case LRTVDBArtworkTypeFanart:
                [fanartArray addObject:artwork];
                break;
            case LRTVDBArtworkTypePoster:
                [posterArray addObject:artwork];
                break;
            case LRTVDBArtworkTypeSeason:
                [seasonArray addObject:artwork];
                break;
            case LRTVDBArtworkTypeBanner:
                [bannerArray addObject:artwork];
                break;
            default:
                break;
        }
    }
    
    self.fanartArtworks = [fanartArray copy];
    self.posterArtworks = [posterArray copy];
    self.seasonArtworks = [seasonArray copy];
    self.bannerArtworks = [bannerArray copy];
}

#pragma mark - Actors handling

- (void)addActors:(NSArray *)actors
{
    if (self.mutableActors == nil)
    {
        self.mutableActors = [NSMutableOrderedSet orderedSet];
    }
    
    // Assumption: actors are newer than the ones we may already have.
    NSMutableOrderedSet *updatedActors = [NSMutableOrderedSet orderedSetWithArray:actors];
    [updatedActors unionOrderedSet:self.mutableActors];
    [updatedActors sortUsingComparator:actorsComparisonBlock];
    
    self.mutableActors = [updatedActors copy];
    self.actors = [self.mutableActors copy];
}

#pragma mark - Update show

- (void)updateWithShow:(LRTVDBShow *)updatedShow
{
    NSAssert([self isEqual:updatedShow], @"Trying to update show with one with different ID?");
    
    self.showID = updatedShow.showID;
    self.name = updatedShow.name;
    self.overview = updatedShow.overview;
    self.imdbID = updatedShow.imdbID;
    self.language = updatedShow.language;
    self.airDay = updatedShow.airDay;
    self.airTime = updatedShow.airTime;
    self.contentRating = updatedShow.contentRating;
    self.genres = updatedShow.genres;
    self.actorsNames = updatedShow.actorsNames;
    self.network = updatedShow.network;
    self.runtime = updatedShow.runtime;
    self.showStatusString = updatedShow.showStatusString;
    self.bannerURLString = updatedShow.bannerURLString;
    self.fanartURLString = updatedShow.fanartURLString;
    self.posterURLString = updatedShow.posterURLString;
    self.premiereDateString = updatedShow.premiereDateString;
    self.ratingString = updatedShow.ratingString;
    self.ratingCountString = updatedShow.ratingCountString;
    
    // Updates relationship info.
    
    if (updatedShow.episodes.count > 0)
    {
        [self addEpisodes:updatedShow.episodes.array];
    }
    
    if (updatedShow.artworks.count > 0)
    {
        [self addArtworks:updatedShow.artworks.array];
    }
    
    if (updatedShow.actors.count > 0)
    {
        [self addActors:updatedShow.actors.array];
    }
}

#pragma mark - LRKVCBaseModelProtocol

- (NSDictionary *)mappings
{
    return @{ @"SeriesName" : @"name",
              @"id" : @"showID",
              @"Language" : @"language",
              @"language" : @"language",
              @"banner" : @"bannerURLString",
              @"poster" : @"posterURLString",
              @"fanart" : @"fanartURLString",
              @"Overview" : @"overview",
              @"FirstAired" : @"premiereDateString",
              @"IMDB_ID" : @"imdbID",
              @"Airs_DayOfWeek" : @"airDay",
              @"Airs_Time" : @"airTime",
              @"ContentRating" : @"contentRating",
              @"Genre" : @"genres",
              @"Actors" : @"actorsNames",
              @"Network" : @"network",
              @"Runtime" : @"runtime",
              @"Status" : @"showStatusString",
              @"Rating" : @"ratingString",
              @"RatingCount" : @"ratingCountString"
            };
}

#pragma mark - Equality methods

- (BOOL)isEqual:(id)object
{
    return [self.showID isEqualToString:[(LRTVDBShow *)object showID]];
}

- (NSUInteger)hash
{
    return [self.showID hash];
}

#pragma mark - Description

- (NSString *)description
{
	return [NSString stringWithFormat:@"\nID: %@\nName: %@\nOverview: %@\n", self.showID, self.name, self.overview];
}

@end
