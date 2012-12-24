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
#import "NSArray+LRTVDBAdditions.h"

/**
 Show comparison block.
 */
NSComparator LRTVDBShowComparator = ^NSComparisonResult(LRTVDBShow *firstShow, LRTVDBShow *secondShow)
{
    NSComparisonResult daysComparison = !secondShow.daysToNextEpisode ? NSOrderedSame : [firstShow.daysToNextEpisode compare:secondShow.daysToNextEpisode];
    NSComparisonResult statusComparison = [@(firstShow.showStatus) compare:@(secondShow.showStatus)];
    NSComparisonResult nameComparison = !secondShow.name ? NSOrderedSame : [firstShow.name compare:secondShow.name options:NSCaseInsensitiveSearch];
        
    if (daysComparison != NSOrderedSame)
    {
        return daysComparison;
    }
    else if (statusComparison != NSOrderedSame)
    {
        return statusComparison;
    }
    else
    {
        return nameComparison;
    }
};

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

@interface LRTVDBShow ()

@property (nonatomic, copy) NSString *showID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *overview;
@property (nonatomic, copy) NSString *imdbID;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy) NSString *airDay;
@property (nonatomic, copy) NSString *airTime;
@property (nonatomic, copy) NSString *contentRating;
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

@property (nonatomic, copy) NSArray *genres;
@property (nonatomic, copy) NSArray *actorsNames;

@property (nonatomic, copy) NSArray *episodes;
@property (nonatomic, strong) LRTVDBEpisode *lastEpisode;
@property (nonatomic, strong) LRTVDBEpisode *nextEpisode;
@property (nonatomic, strong) NSNumber *daysToNextEpisode;
@property (nonatomic, strong) NSNumber *numberOfSeasons;

@property (nonatomic, copy) NSArray *artworks;
@property (nonatomic, copy) NSArray *fanartArtworks;
@property (nonatomic, copy) NSArray *posterArtworks;
@property (nonatomic, copy) NSArray *seasonArtworks;
@property (nonatomic, copy) NSArray *bannerArtworks;

@property (nonatomic, copy) NSArray *actors;

@property (nonatomic, copy) NSString *bannerURLString;
@property (nonatomic, copy) NSString *posterURLString;
@property (nonatomic, copy) NSString *fanartURLString;

@property (nonatomic, copy) NSString *ratingString;
@property (nonatomic, copy) NSString *ratingCountString;
@property (nonatomic, copy) NSString *showStatusString;
@property (nonatomic, copy) NSString *premiereDateString;

@property (nonatomic, strong) NSMutableDictionary *seasonToEpisodesDictionary;

@property (nonatomic, copy) NSString *genresList; /** |Genre 1|Genre 2|... */
@property (nonatomic, copy) NSString *actorsNamesList; /** |Actor 1|Actor 2|... */

@end

@implementation LRTVDBShow

#pragma mark - Initializer

+ (instancetype)showWithDictionary:(NSDictionary *)dictionary
{
    return [[self alloc] initWithDictionary:dictionary];
}

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

- (void)setGenresList:(NSString *)genresList
{
    _genresList = genresList;
    self.genres = [[_genresList pipedStringToArray] arrayByRemovingDuplicates];
}

- (void)setActorsNamesList:(NSString *)actorsNamesList
{
    _actorsNamesList = actorsNamesList;
    self.actorsNames = [[_actorsNamesList pipedStringToArray] arrayByRemovingDuplicates];
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
    [self willChangeValueForKey:@"episodes"];
    
    _episodes = [self mergeObjects:episodes
                       withObjects:self.episodes
                   comparisonBlock:LRTVDBEpisodeComparator];
    
    [_episodes makeObjectsPerformSelector:@selector(setShow:) withObject:self];
    
    [self refreshEpisodesInfomation];
    
    [self didChangeValueForKey:@"episodes"];
}

- (void)refreshEpisodesInfomation
{
    self.seasonToEpisodesDictionary = nil; // Regenerate
    __block BOOL lastEpisodeSet = NO;
    
    // Last episode
    if (self.showBasicStatus == LRTVDBShowBasicStatusEnded)
    {
        self.lastEpisode = self.episodes.lastObject;
        lastEpisodeSet = YES;
    }
    else
    {
        NSDate *fromDate = [[NSDate date] dateByIgnoringTime];
        
        void (^block)(LRTVDBEpisode *, NSUInteger, BOOL *) = ^(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop)
        {
            NSDate *toDate = [episode.airedDate dateByIgnoringTime];
            
            if ([toDate compare:fromDate] == NSOrderedAscending)
            {
                self.lastEpisode = episode;
                lastEpisodeSet = YES;
                *stop = YES;
            }
        };
        
        [self.episodes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:block];
        
        if (!lastEpisodeSet)
        {
            self.lastEpisode = self.episodes.lastObject;
        }
    }
    
    // Next episode
    NSUInteger nextEpisodeIndex = [self.episodes indexOfObject:self.lastEpisode] + 1;
    BOOL notValidNextEpisode = nextEpisodeIndex >= self.episodes.count ||
                               [(self.episodes)[nextEpisodeIndex] airedDate] == nil;
    self.nextEpisode = notValidNextEpisode ? nil : (self.episodes)[nextEpisodeIndex];
    
    // Days to next episode
    self.daysToNextEpisode = [self daysToEpisode:self.nextEpisode];
    
    // Number of seasons
    self.numberOfSeasons = [self.episodes.lastObject seasonNumber];
    
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
    NSDate *toDate = [episode.airedDate dateByIgnoringTime];
    
    NSDateComponents *components = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate
                                                 toDate:toDate
                                                options:0];
    return @(components.day);
}

- (NSArray *)episodesForSeason:(NSNumber *)seasonNumber
{
    if (self.episodes == nil || seasonNumber < 0) return @[];

    if (self.seasonToEpisodesDictionary == nil)
    {
        self.seasonToEpisodesDictionary = [@{} mutableCopy];
    }
    
    NSArray *episodes = (self.seasonToEpisodesDictionary)[seasonNumber];
    
    if (!episodes)
    {
        NSIndexSet *indexSet = [self.episodes indexesOfObjectsPassingTest:^BOOL(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop)
        {
            return [episode.seasonNumber isEqualToNumber:seasonNumber];
        }];
        
        episodes = [self.episodes objectsAtIndexes:indexSet];
        
        (self.seasonToEpisodesDictionary)[seasonNumber] = episodes;
    }
    
    return episodes;
}

#pragma mark - Artwork handling

- (void)addArtworks:(NSArray *)artworks
{
    [self willChangeValueForKey:@"artworks"];
    
    _artworks = [self mergeObjects:artworks
                       withObjects:self.artworks
                   comparisonBlock:LRTVDBArtworkComparator];
    
    [self computeArtworkInfomation];
    
    [self didChangeValueForKey:@"artworks"];
}

- (void)computeArtworkInfomation
{
    NSMutableArray *fanartArray = [@[] mutableCopy];
    NSMutableArray *posterArray = [@[] mutableCopy];
    NSMutableArray *seasonArray = [@[] mutableCopy];
    NSMutableArray *bannerArray = [@[] mutableCopy];
    
    for (LRTVDBArtwork *artwork in self.artworks)
    {
        switch (artwork.type)
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
    
    self.fanartArtworks = fanartArray;
    self.posterArtworks = posterArray;
    self.seasonArtworks = seasonArray;
    self.bannerArtworks = bannerArray;
}

#pragma mark - Actors handling

- (void)addActors:(NSArray *)actors
{
    self.actors = [self mergeObjects:actors
                         withObjects:self.actors
                     comparisonBlock:LRTVDBActorComparator];
}

#pragma mark - Update show

- (void)updateWithShow:(LRTVDBShow *)updatedShow
{
    if (updatedShow == nil) return;
  
    NSAssert([self isEqual:updatedShow], @"Trying to update show with one with different ID?");
    
    self.showID = updatedShow.showID;
    self.name = updatedShow.name;
    self.overview = updatedShow.overview;
    self.imdbID = updatedShow.imdbID;
    self.language = updatedShow.language;
    self.airDay = updatedShow.airDay;
    self.airTime = updatedShow.airTime;
    self.contentRating = updatedShow.contentRating;
    self.genresList = updatedShow.genresList;
    self.actorsNamesList = updatedShow.actorsNamesList;
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
    [self addEpisodes:updatedShow.episodes];
    [self addArtworks:updatedShow.artworks];
    [self addActors:updatedShow.actors];
}

#pragma mark - Private

/**
 @remarks This method could have been easily implemented using
 NSSet's methods, but binary search performs much faster.
 */
- (NSArray *)mergeObjects:(NSArray *)newObjects
              withObjects:(NSArray *)oldObjects
          comparisonBlock:(NSComparator)comparator
{
    NSArray *mergedObjects = nil;
    
    if (newObjects.count == 0)
    {
        mergedObjects = [[oldObjects arrayByRemovingDuplicates] sortedArrayUsingComparator:comparator];
    }
    else if (oldObjects.count == 0)
    {
        mergedObjects = [[newObjects arrayByRemovingDuplicates] sortedArrayUsingComparator:comparator];
    }
    else
    {
        NSMutableArray *mutableOldObjects = [oldObjects mutableCopy];
        [mutableOldObjects removeObjectsInArray:newObjects];
        
        for (id newObject in newObjects)
        {
            NSUInteger newIndexToInsertNewObject = [mutableOldObjects indexOfObject:newObject
                                                                      inSortedRange:NSMakeRange(0, mutableOldObjects.count)
                                                                            options:NSBinarySearchingInsertionIndex
                                                                    usingComparator:comparator];
            if (newIndexToInsertNewObject != NSNotFound)
            {
                [mutableOldObjects insertObject:newObject atIndex:newIndexToInsertNewObject];
            }
        }
        
        mergedObjects = [mutableOldObjects arrayByRemovingDuplicates];
    }
    
    return mergedObjects ? : @[];
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
              @"Genre" : @"genresList",
              @"Actors" : @"actorsNamesList",
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

- (NSComparisonResult)compare:(id)object
{
    return LRTVDBShowComparator(self, object);
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"\nID: %@\nName: %@\nOverview: %@\n", self.showID, self.name, self.overview];
}

@end
