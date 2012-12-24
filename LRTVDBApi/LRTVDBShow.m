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
    // Days to next episode
    NSNumber *firstShowDaysToNextEpisode = firstShow.daysToNextEpisode ? : @(NSIntegerMax);
    NSNumber *secondShowDaysToNextEpisode = secondShow.daysToNextEpisode ? : @(NSIntegerMax);
    
    NSComparisonResult comparisonResult = [firstShowDaysToNextEpisode compare:secondShowDaysToNextEpisode];
    
    if (comparisonResult == NSOrderedSame)
    {
        // status: unknown status at the end
        LRTVDBShowStatus firstShowStatus = firstShow.status;
        LRTVDBShowStatus secondShowStatus = secondShow.status;
        
        if (firstShowStatus == LRTVDBShowStatusUnknown) { firstShowStatus = NSIntegerMax; }
        if (secondShowStatus == LRTVDBShowStatusUnknown) { secondShowStatus = NSIntegerMax; }
        
        comparisonResult = [@(firstShowStatus) compare:@(secondShowStatus)];
        
        if (comparisonResult == NSOrderedSame)
        {
            // Rating
            NSNumber *firstShowRating = firstShow.rating ? : @(0);
            NSNumber *secondShowRating = secondShow.rating ? : @(0);
            comparisonResult = [secondShowRating compare:firstShowRating];
            
            if (comparisonResult == NSOrderedSame)
            {
                // Rating count
                NSNumber *firstShowRatingCount = firstShow.ratingCount ? : @(0);
                NSNumber *secondShowRatingCount = secondShow.ratingCount ? : @(0);
                comparisonResult = [secondShowRatingCount compare:firstShowRatingCount];
                
                if (comparisonResult == NSOrderedSame)
                {
                    // Name
                    if (!secondShow.name && !firstShow.name)
                    {
                        comparisonResult = NSOrderedSame;
                    }
                    else if (!secondShow.name)
                    {
                        comparisonResult = NSOrderedAscending;
                    }
                    else if (!firstShow.name)
                    {
                        comparisonResult = NSOrderedDescending;
                    }
                    else
                    {
                        comparisonResult = [firstShow.name compare:secondShow.name options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)];
                    }
                }
            }
        }
    }
    
    return comparisonResult;
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
@property (nonatomic) LRTVDBShowStatus status;
@property (nonatomic) LRTVDBShowBasicStatus basicStatus;

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
@property (nonatomic, copy) NSString *basicStatusString;
@property (nonatomic, copy) NSString *premiereDateString;

@property (nonatomic, strong) NSMutableDictionary *seasonToEpisodesDictionary;

@property (nonatomic, copy) NSString *genresList; /** |Genre 1|Genre 2|... */
@property (nonatomic, copy) NSString *actorsNamesList; /** |Actor 1|Actor 2|... */

@property (nonatomic) dispatch_queue_t syncQueue;

@end

@implementation LRTVDBShow

#pragma mark - Initializer

+ (instancetype)showWithDictionary:(NSDictionary *)dictionary
{
    return [[self alloc] initWithDictionary:dictionary];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super initWithDictionary:dictionary];
    
    if (self)
    {
        _syncQueue = dispatch_queue_create("com.LRTVDBAPI.LRTVDBShowQueue", NULL);
    }
    
    return self;
}

#pragma mark - Episodes handling

- (NSArray *)episodes
{
    __block NSArray *localEpisodes = nil;
    dispatch_sync(self.syncQueue, ^{
        localEpisodes = _episodes;
    });
    return localEpisodes;
}

- (void)addEpisodes:(NSArray *)episodes
{
    dispatch_sync(self.syncQueue, ^{
        [self willChangeValueForKey:@"episodes"];
        
        _episodes = [self mergeObjects:episodes
                           withObjects:_episodes
                       comparisonBlock:LRTVDBEpisodeComparator];
        
        [_episodes makeObjectsPerformSelector:@selector(setShow:) withObject:self];
        
        [self refreshEpisodesInfomation];
        
        [self didChangeValueForKey:@"episodes"];
    });
}

- (void)refreshEpisodesInfomation
{    
    // Last episode
    if (self.basicStatus == LRTVDBShowBasicStatusEnded)
    {
        self.lastEpisode = _episodes.lastObject;
    }
    else
    {
        __block BOOL lastEpisodeSet = NO;

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
        
        [_episodes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:block];
        
        if (!lastEpisodeSet)
        {
            self.lastEpisode = _episodes.lastObject;
        }
    }
    
    // Next episode
    NSUInteger nextEpisodeIndex = [_episodes indexOfObject:self.lastEpisode] + 1;
    BOOL notValidNextEpisode = nextEpisodeIndex >= _episodes.count ||
                               [_episodes[nextEpisodeIndex] airedDate] == nil;
    self.nextEpisode = notValidNextEpisode ? nil : (_episodes)[nextEpisodeIndex];
    
    // Days to next episode
    self.daysToNextEpisode = [self daysToEpisode:self.nextEpisode];
    
    // Number of seasons
    self.numberOfSeasons = [_episodes.lastObject seasonNumber];
    
    // Show status
    if (self.basicStatus == LRTVDBShowStatusEnded)
    {
        self.status = LRTVDBShowStatusEnded;
    }
    else if (self.basicStatus == LRTVDBShowBasicStatusContinuing)
    {
        self.status =  [self.daysToNextEpisode isEqualToNumber:@(NSIntegerMax)] ?
        LRTVDBShowStatusTBA : LRTVDBShowStatusUpcoming;
    }
    else
    {
        self.status = LRTVDBShowStatusUnknown;
    }
    
    // Re compute season dictionary
    self.seasonToEpisodesDictionary = [NSMutableDictionary dictionary];
    
    NSUInteger firstSeason = [[_episodes firstObject] seasonNumber].unsignedIntegerValue;
    
    for (NSUInteger seasonNumber = firstSeason; seasonNumber <= self.numberOfSeasons.unsignedIntegerValue; seasonNumber++)
    {
        NSIndexSet *indexSet = [_episodes indexesOfObjectsPassingTest:^BOOL(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop) {
            return [episode.seasonNumber isEqualToNumber:@(seasonNumber)];
        }];
                
        (self.seasonToEpisodesDictionary)[@(seasonNumber)] = [_episodes objectsAtIndexes:indexSet];
    }
}

- (NSNumber *)daysToEpisode:(LRTVDBEpisode *)episode
{
    if (episode.airedDate == nil) return @(NSIntegerMax);
    
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
    return (self.seasonToEpisodesDictionary)[seasonNumber];
}

#pragma mark - Artwork handling

- (NSArray *)artworks
{
    __block NSArray *localArtworks = nil;
    dispatch_sync(self.syncQueue, ^{
        localArtworks = _artworks;
    });
    return localArtworks;
}

- (void)addArtworks:(NSArray *)artworks
{
    dispatch_sync(self.syncQueue, ^{
        [self willChangeValueForKey:@"artworks"];
        
        _artworks = [self mergeObjects:artworks
                           withObjects:_artworks
                       comparisonBlock:LRTVDBArtworkComparator];
        
        [self computeArtworkInfomation];
        
        [self didChangeValueForKey:@"artworks"];
    });
}

- (void)computeArtworkInfomation
{
    NSMutableArray *fanartArray = [NSMutableArray array];
    NSMutableArray *posterArray = [NSMutableArray array];
    NSMutableArray *seasonArray = [NSMutableArray array];
    NSMutableArray *bannerArray = [NSMutableArray array];
    
    for (LRTVDBArtwork *artwork in _artworks)
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

- (NSArray *)actors
{
    __block NSArray *localActors = nil;
    dispatch_sync(self.syncQueue, ^{
        localActors = _actors;
    });
    return localActors;
}

- (void)addActors:(NSArray *)actors
{
    dispatch_sync(self.syncQueue, ^{
        _actors = [self mergeObjects:actors
                         withObjects:_actors
                     comparisonBlock:LRTVDBActorComparator];
    });
};

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
    self.basicStatusString = updatedShow.basicStatusString;
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
        NSArray *copiedNewObjects = [newObjects copy];
        [mutableOldObjects removeObjectsInArray:copiedNewObjects];
        
        for (id newObject in copiedNewObjects)
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

- (void)setBasicStatusString:(NSString *)basicStatusString
{
    _basicStatusString = basicStatusString;
    
    if ([_basicStatusString isEqualToString:kLRTVDBShowBasicStatusContinuingKey])
    {
        self.basicStatus = LRTVDBShowBasicStatusContinuing;
    }
    else if ([_basicStatusString isEqualToString:kLRTVDBShowBasicStatusEndedKey])
    {
        self.basicStatus = LRTVDBShowStatusEnded;
    }
    else
    {
        self.basicStatus = LRTVDBShowStatusUnknown;
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
              @"Genre" : @"genresList",
              @"Actors" : @"actorsNamesList",
              @"Network" : @"network",
              @"Runtime" : @"runtime",
              @"Status" : @"basicStatusString",
              @"Rating" : @"ratingString",
              @"RatingCount" : @"ratingCountString"
            };
}

#pragma mark - Equality methods

- (BOOL)isEqual:(id)object
{
    NSParameterAssert([object isKindOfClass:[LRTVDBShow class]]);
    
    if (![object isKindOfClass:[LRTVDBShow class]])
    {
        return NO;
    }
    else
    {
        return [self.showID isEqualToString:[(LRTVDBShow *)object showID]];
    }
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
