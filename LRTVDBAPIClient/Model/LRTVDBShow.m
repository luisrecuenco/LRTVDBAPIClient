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

#import "LRTVDBShow+Private.h"
#import "LRTVDBEpisode+Private.h"
#import "LRTVDBImage+Private.h"
#import "LRTVDBActor+Private.h"
#import "NSDate+LRTVDBAdditions.h"

#pragma mark - LRUpdate categories

@interface LRTVDBEpisode (LRUpdate)

- (void)updateWithObject:(LRTVDBEpisode *)episode;

@end

@interface LRTVDBImage (LRUpdate)

- (void)updateWithObject:(LRTVDBImage *)image;

@end

@interface LRTVDBActor (LRUpdate)

- (void)updateWithObject:(LRTVDBActor *)actor;

@end

@implementation LRTVDBEpisode (LRUpdate)

- (void)updateWithObject:(LRTVDBEpisode *)episode
{
    [self updateWithEpisode:episode];
}

@end

@implementation LRTVDBImage (LRUpdate)

- (void)updateWithObject:(LRTVDBImage *)image
{
    [self updateWithImage:image];
}

@end

@implementation LRTVDBActor (LRUpdate)

- (void)updateWithObject:(LRTVDBActor *)actor
{
    [self updateWithActor:actor];
}

@end

#pragma mark - LRTVDBShow implementation

// Persistence keys
static NSString *const kShowIDKey = @"kShowIDKey";
static NSString *const kShowNameKey = @"kShowNameKey";
static NSString *const kShowOverviewKey = @"kShowOverviewKey";
static NSString *const kShowAirDayKey = @"kShowAirDayKey";
static NSString *const kShowAirTimeKey = @"kShowAirTimeKey";
static NSString *const kShowFanartURLKey = @"kShowFanartURLKey";
static NSString *const kShowBannerURLKey = @"kShowBannerURLKey";
static NSString *const kShowPosterURLKey = @"kShowPosterURLKey";
static NSString *const kShowPremiereDateKey = @"kShowPremiereDateKey";
static NSString *const kShowGenresKey = @"kShowGenresKey";
static NSString *const kShowActorsNamesKey = @"kShowActorsNamesKey";
static NSString *const kShowImdbIDKey = @"kShowImdbIDKey";
static NSString *const kShowNetworkKey = @"kShowNetworkKey";
static NSString *const kShowLanguageKey = @"kShowLanguageKey";
static NSString *const kShowRatingKey = @"kShowRatingKey";
static NSString *const kShowRatingCountKey = @"kShowRatingCountKey";
static NSString *const kShowBasicStatusKey = @"kShowBasicStatusKey";
static NSString *const kShowLastEpisodeSeenKey = @"kShowLastEpisodeSeenKey";
static NSString *const kShowContentRatingKey = @"kShowContentRatingKey";
static NSString *const kShowRuntimeKey = @"kShowRuntimeKey";
static NSString *const kShowActorsKey = @"kShowActorsKey";
static NSString *const kShowEpisodesKey = @"kShowEpisodesKey";
static NSString *const kShowImagesKey = @"kShowImagesKey";

#if OS_OBJECT_USE_OBJC
#define LRDispatchQueuePropertyModifier strong
#else
#define LRDispatchQueuePropertyModifier assign
#endif

const struct LRTVDBShowAttributes LRTVDBShowAttributes = {
    .activeEpisode = @"activeEpisode",
    .fanartURL = @"fanartURL",
    .posterURL = @"posterURL",
    .lastEpisode = @"lastEpisode",
    .episodes = @"episodes",
    .images = @"images",
    .actors = @"actors",
};

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
@property (nonatomic, strong) NSDate *premiereDate;
@property (nonatomic, strong) NSNumber *runtime;
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

@property (nonatomic, strong) LRTVDBEpisode *activeEpisode;
@property (nonatomic, strong) NSNumber *daysToActiveEpisode;
@property (nonatomic, strong) NSNumber *numberOfEpisodesBehind;

@property (nonatomic, strong) NSMutableArray *seenEpisodes;

@property (nonatomic, copy) NSArray *images;
@property (nonatomic, copy) NSArray *fanartImages;
@property (nonatomic, copy) NSArray *posterImages;
@property (nonatomic, copy) NSArray *seasonImages;
@property (nonatomic, copy) NSArray *bannerImages;

@property (nonatomic, copy) NSArray *actors;

@property (nonatomic, strong) NSMutableDictionary *seasonToEpisodesDictionary;

@property (nonatomic, LRDispatchQueuePropertyModifier) dispatch_queue_t syncQueue;

@end

@implementation LRTVDBShow

- (void)dealloc
{
#if !OS_OBJECT_USE_OBJC
    if (_syncQueue != NULL)
    {
        dispatch_release(_syncQueue);
    }
#endif
    _syncQueue = NULL;
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
        [self willChangeValueForKey:LRTVDBShowAttributes.episodes];
        
        _episodes = [[self mergeObjects:episodes
                            withObjects:_episodes
                        comparisonBlock:LRTVDBEpisodeComparator] copy];
        
        // Assign weak reference to the show.
        for (LRTVDBEpisode *episode in _episodes)
        {
            episode.show = self;
        }
        
        [self refreshEpisodesInfomation];
        
        [self didChangeValueForKey:LRTVDBShowAttributes.episodes];
    });
}

- (void)refreshEpisodesInfomation
{
    // Last episode
    if (self.basicStatus == LRTVDBShowBasicStatusEnded)
    {
        self.lastEpisode = [_episodes lastObject];
    }
    else
    {
        NSDate *fromDate = [[NSDate date] dateByIgnoringTime];
        
        void (^block)(LRTVDBEpisode *, NSUInteger, BOOL *) = ^(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop) {
            
            NSDate *toDate = [episode.airedDate dateByIgnoringTime];
            
            if ([toDate compare:fromDate] == NSOrderedAscending)
            {
                self.lastEpisode = episode;
                *stop = YES;
            }
        };
        
        [_episodes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:block];
    }
    
    // Next episode

    if (self.lastEpisode == nil)
    {
        self.nextEpisode = [_episodes firstObject];
    }
    else
    {
        NSUInteger nextEpisodeIndex = [_episodes indexOfObjectIdenticalTo:self.lastEpisode] + 1;
        BOOL notValidNextEpisode = nextEpisodeIndex >= [_episodes count];
        self.nextEpisode = notValidNextEpisode ? nil : _episodes[nextEpisodeIndex];
    }
    
    // Days to next episode
    self.daysToNextEpisode = [self daysToEpisode:self.nextEpisode];
    
    // Number of seasons
    self.numberOfSeasons = [[_episodes lastObject] seasonNumber];
    
    // Show status
    if (self.basicStatus == LRTVDBShowBasicStatusEnded)
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
    NSMutableDictionary *newSeasonToEpisodesDictionary = [NSMutableDictionary dictionary];
    
    self.seenEpisodes = nil; // Recompute

    for (LRTVDBEpisode *episode in _episodes)
    {
        NSMutableArray *episodesForSeason = [newSeasonToEpisodesDictionary[episode.seasonNumber] mutableCopy];
        if (episodesForSeason == nil)
        {
            episodesForSeason = [NSMutableArray array];
        }
        
        [episodesForSeason addObject:episode];
        
        newSeasonToEpisodesDictionary[episode.seasonNumber] = [episodesForSeason copy];
        
        [self seenStatusDidChangeForEpisode:episode];
    }
    
    self.seasonToEpisodesDictionary = newSeasonToEpisodesDictionary;
    
    [self reloadActiveEpisode];
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

- (NSArray *)specials
{
    return [self episodesForSeason:@(0)];
}

- (NSArray *)episodesForSeason:(NSNumber *)seasonNumber
{
    return self.seasonToEpisodesDictionary[seasonNumber] ? : @[];
}

#pragma mark - Images handling

- (NSArray *)images
{
    __block NSArray *localImages = nil;
    dispatch_sync(self.syncQueue, ^{
        localImages = _images;
    });
    return localImages;
}

- (void)addImages:(NSArray *)images
{
    dispatch_sync(self.syncQueue, ^{
        [self willChangeValueForKey:LRTVDBShowAttributes.images];
        
        _images = [[self mergeObjects:images
                          withObjects:_images
                      comparisonBlock:LRTVDBImageComparator] copy];
        
        [self computeImagesInformation];
        
        [self didChangeValueForKey:LRTVDBShowAttributes.images];
    });
}

- (void)computeImagesInformation
{
    NSMutableArray *fanartArray = [NSMutableArray array];
    NSMutableArray *posterArray = [NSMutableArray array];
    NSMutableArray *seasonArray = [NSMutableArray array];
    NSMutableArray *bannerArray = [NSMutableArray array];
    
    for (LRTVDBImage *image in _images)
    {
        switch (image.type)
        {
            case LRTVDBImageTypeFanart:
                [fanartArray addObject:image];
                break;
            case LRTVDBImageTypePoster:
                [posterArray addObject:image];
                break;
            case LRTVDBImageTypeSeason:
                [seasonArray addObject:image];
                break;
            case LRTVDBImageTypeBanner:
                [bannerArray addObject:image];
                break;
            default:
                break;
        }
    }
    
    self.fanartImages = fanartArray;
    self.posterImages = posterArray;
    self.seasonImages = seasonArray;
    self.bannerImages = bannerArray;
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
        [self willChangeValueForKey:LRTVDBShowAttributes.actors];
        
        _actors = [[self mergeObjects:actors
                          withObjects:_actors
                      comparisonBlock:LRTVDBActorComparator] copy];
        
        [self didChangeValueForKey:LRTVDBShowAttributes.actors];
    });
};

#pragma mark - Sync Queue

- (dispatch_queue_t)syncQueue
{
    if (_syncQueue == NULL)
    {
        _syncQueue = dispatch_queue_create("com.LRTVDBAPIClient.LRTVDBShowQueue", NULL);
    }
    
    return _syncQueue;
}

#pragma mark - IMDB URL

- (NSURL *)imdbURL
{
    if (!self.imdbID) return nil;
    
    return [NSURL URLWithString:[NSString stringWithFormat:
                                 @"http://www.imdb.com/title/%@/", self.imdbID]];
}

#pragma mark - Active episode

- (LRTVDBEpisode *)activeEpisode
{
    if (!_activeEpisode)
    {
        if (![self hasBeenFinished])
        {
            for (LRTVDBEpisode *episode in _episodes)
            {
                if (![episode hasBeenSeen] && ![episode isSpecial])
                {
                    _activeEpisode = episode;
                    break;
                }
            }
        }
        else
        {
            _activeEpisode = self.nextEpisode ? : self.lastEpisode;
            
            if (_activeEpisode == self.nextEpisode && _activeEpisode.seen)
            {
                NSUInteger index = [_episodes indexOfObjectIdenticalTo:_activeEpisode];
                
                if (index < [_episodes count] - 1)
                {
                    _activeEpisode = _episodes[index + 1];
                }
            }
        }
    }
    
    return _activeEpisode;
}

- (NSNumber *)daysToActiveEpisode
{
    if (!_daysToActiveEpisode)
    {
        _daysToActiveEpisode = [self daysToEpisode:self.activeEpisode];
    }
    
    return _daysToActiveEpisode;
}

#pragma mark - Seen episodes

- (NSMutableArray *)seenEpisodes
{
    if (!_seenEpisodes)
    {
        _seenEpisodes = [NSMutableArray array];
    }

    return _seenEpisodes;
}

#pragma mark - Number of episodes behind

- (NSNumber *)numberOfEpisodesBehind
{
    if (!_numberOfEpisodesBehind)
    {
        NSIndexSet *indexSet = [_episodes indexesOfObjectsPassingTest:^BOOL(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop) {
            return [episode hasAlreadyAired] && ![episode isSpecial];
        }];
        
        NSArray *airedEpisodes = [_episodes objectsAtIndexes:indexSet];
        
        _numberOfEpisodesBehind = @([airedEpisodes count] - [self.seenEpisodes count]);
        
        // The episode that airs today can be marked as seen but doesn't count for the episodes
        // behind count
        if ([self.daysToNextEpisode isEqualToNumber:@0] && !self.nextEpisode.seen)
        {
            _numberOfEpisodesBehind = @([_numberOfEpisodesBehind unsignedIntegerValue] - 1);
        }
    }
    
    return _numberOfEpisodesBehind;
}

#pragma mark - Is show active?

- (BOOL)isActive
{
    return [self.seenEpisodes count] > 0;
}

#pragma mark - Has show been finished?

- (BOOL)hasBeenFinished
{
    return [self.numberOfEpisodesBehind isEqualToNumber:@0] && [self hasStarted];
}

#pragma mark - Has show started?

- (BOOL)hasStarted
{
    return [[_episodes firstObject] hasAlreadyAired];
}

#pragma mark - Handle episodes seen changes

- (void)seenStatusDidChangeForEpisode:(LRTVDBEpisode *)episode
{
    // Special episodes or those without aire date doesn't change the active episode
    if ([episode isSpecial] || !episode.airedDate)
    {
        return;
    }
    
    if (episode.seen)
    {
        [self.seenEpisodes addObject:episode];
    }
    else
    {
        [self.seenEpisodes removeObject:episode];
    }
}

- (void)reloadActiveEpisode
{
    self.numberOfEpisodesBehind = nil;
    self.activeEpisode = nil;
    self.daysToActiveEpisode = nil;
}

#pragma mark - Update show

- (void)updateWithShow:(LRTVDBShow *)updatedShow
        updateEpisodes:(BOOL)updateEpisodes
          updateImages:(BOOL)updateImages
          updateActors:(BOOL)updateActors
        replaceArtwork:(BOOL)replaceArtwork
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
    self.genres = updatedShow.genres;
    self.actorsNames = updatedShow.actorsNames;
    self.network = updatedShow.network;
    self.runtime = updatedShow.runtime;
    self.basicStatus = updatedShow.basicStatus;
    self.premiereDate = updatedShow.premiereDate;
    self.rating = updatedShow.rating;
    self.ratingCount = updatedShow.ratingCount;

    self.bannerURL = replaceArtwork ? updatedShow.bannerURL : self.bannerURL;
    self.fanartURL = replaceArtwork ? updatedShow.fanartURL : self.fanartURL;
    self.posterURL = replaceArtwork ? updatedShow.posterURL : self.posterURL;

    // Updates relationship info.
    
    if (updateEpisodes)
    {
        [self addEpisodes:updatedShow.episodes];
    }
    
    if (updateImages)
    {
        [self addImages:updatedShow.images];
    }
    
    if (updateActors)
    {
        [self addActors:updatedShow.actors];
    }
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
    
    if ([newObjects count] == 0)
    {
        mergedObjects = [[oldObjects arrayByRemovingDuplicates] sortedArrayUsingComparator:comparator];
    }
    else if ([oldObjects count] == 0)
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
                                                                      inSortedRange:NSMakeRange(0, [mutableOldObjects count])
                                                                            options:NSBinarySearchingInsertionIndex
                                                                    usingComparator:comparator];
            if (newIndexToInsertNewObject != NSNotFound)
            {
                if (newIndexToInsertNewObject < [oldObjects count])
                {
                    id oldObject = oldObjects[newIndexToInsertNewObject];
                    
                    if ([oldObject isEqual:newObject])
                    {
                        [oldObject updateWithObject:newObject];
                        
                        [mutableOldObjects insertObject:oldObject atIndex:newIndexToInsertNewObject];
                    }
                    else
                    {
                        [mutableOldObjects insertObject:newObject atIndex:newIndexToInsertNewObject];
                    }
                }
                else
                {
                    [mutableOldObjects insertObject:newObject atIndex:newIndexToInsertNewObject];
                }
            }
        }
        
        mergedObjects = [mutableOldObjects arrayByRemovingDuplicates];
    }
    
    return mergedObjects ? : @[];
}

#pragma mark - LRTVDBSerializableModelProtocol

+ (LRTVDBShow *)deserialize:(NSDictionary *)dictionary error:(NSError **)error
{
    LRTVDBShow *show = [[LRTVDBShow alloc] init];
    
    id showId = LREmptyStringToNil(dictionary[kShowIDKey]);
    CHECK_NIL(showId, @"showId", *error);
    CHECK_TYPE(showId, [NSString class], @"showId", *error);
    show.showID = showId;
    
    id showName = LREmptyStringToNil(dictionary[kShowNameKey]);
    CHECK_NIL(showName, @"showName", *error);
    CHECK_TYPE(showName, [NSString class], @"showName", *error);
    show.name = showName;
    
    id overview = LREmptyStringToNil(dictionary[kShowOverviewKey]);
    CHECK_TYPE(overview, [NSString class], @"overview", *error);
    show.overview = overview;
    
    id fanartURL = LREmptyStringToNil(dictionary[kShowFanartURLKey]);
    CHECK_TYPE(fanartURL, [NSString class], @"fanartURL", *error);
    show.fanartURL = [NSURL URLWithString:fanartURL];

    id bannerURL = LREmptyStringToNil(dictionary[kShowBannerURLKey]);
    CHECK_TYPE(bannerURL, [NSString class], @"bannerURL", *error);
    show.bannerURL = [NSURL URLWithString:bannerURL];

    id posterURL = LREmptyStringToNil(dictionary[kShowPosterURLKey]);
    CHECK_TYPE(posterURL, [NSString class], @"posterURL", *error);
    show.posterURL = [NSURL URLWithString:posterURL];

    id airTime = LREmptyStringToNil(dictionary[kShowAirTimeKey]);
    CHECK_TYPE(airTime, [NSString class], @"airTime", *error);
    show.airTime = airTime;

    id airDay = LREmptyStringToNil(dictionary[kShowAirDayKey]);
    CHECK_TYPE(airDay, [NSString class], @"airDay", *error);
    show.airDay = airDay;

    id premiereDate = LREmptyStringToNil(dictionary[kShowPremiereDateKey]);
    CHECK_TYPE(premiereDate, [NSDate class], @"premiereDate", *error);
    show.premiereDate = premiereDate;

    id genres = LREmptyStringToNil(dictionary[kShowGenresKey]);
    CHECK_TYPE(genres, [NSArray class], @"genres", *error);
    show.genres = genres;

    id actorsNames = LREmptyStringToNil(dictionary[kShowActorsNamesKey]);
    CHECK_TYPE(actorsNames, [NSArray class], @"actorsNames", *error);
    show.actorsNames = actorsNames;

    id imdbID = LREmptyStringToNil(dictionary[kShowImdbIDKey]);
    CHECK_TYPE(imdbID, [NSString class], @"imdbID", *error);
    show.imdbID = imdbID;

    id network = LREmptyStringToNil(dictionary[kShowNetworkKey]);
    CHECK_TYPE(network, [NSString class], @"network", *error);
    show.network = network;

    id language = LREmptyStringToNil(dictionary[kShowLanguageKey]);
    CHECK_TYPE(language, [NSString class], @"language", *error);
    show.language = language;

    id rating = LREmptyStringToNil(dictionary[kShowRatingKey]);
    CHECK_TYPE(rating, [NSNumber class], @"rating", *error);
    show.rating = rating;

    id ratingCount = LREmptyStringToNil(dictionary[kShowRatingCountKey]);
    CHECK_TYPE(ratingCount, [NSNumber class], @"ratingCount", *error);
    show.ratingCount = ratingCount;

    id basicStatus = LREmptyStringToNil(dictionary[kShowBasicStatusKey]);
    CHECK_NIL(basicStatus, @"basicStatus", *error);
    CHECK_TYPE(basicStatus, [NSNumber class], @"basicStatus", *error);
    show.basicStatus = [basicStatus unsignedIntegerValue];

    id contentRating = LREmptyStringToNil(dictionary[kShowContentRatingKey]);
    CHECK_TYPE(contentRating, [NSString class], @"contentRating", *error);
    show.contentRating = contentRating;

    // Due to an error in the parser, previous versions of the app may have saved this value
    // as a NSString, let's check both possible values and get a NSNumber out of it.
    id runtime = LREmptyStringToNil(dictionary[kShowRuntimeKey]);
    CHECK_TYPES(runtime, [NSString class], [NSNumber class], @"runtime", *error);
    show.runtime = runtime ? @([[runtime description] integerValue]) : nil;
    
    NSString *lastEpisodeSeenID = LREmptyStringToNil(dictionary[kShowLastEpisodeSeenKey]);
    CHECK_TYPE(lastEpisodeSeenID, [NSString class], @"lastEpisodeSeenID", *error);

    NSArray *episodesDictionaries = LREmptyStringToNil(dictionary[kShowEpisodesKey]);
    NSArray *imagesDictionaries = LREmptyStringToNil(dictionary[kShowImagesKey]);
    NSArray *actorsDictionaries = LREmptyStringToNil(dictionary[kShowActorsKey]);
        
    NSArray *episodes = [self deserializeEpisodes:episodesDictionaries];
    
    if (episodes) [show addEpisodes:episodes];

    NSArray *images = [self deserializeImages:imagesDictionaries];
    
    if (images) [show addImages:images];
    
    NSArray *actors = [self deserializeActors:actorsDictionaries];
    
    if (actors) [show addActors:actors];
    
    if (lastEpisodeSeenID)
    {
        NSUInteger lastEpisodeSeenIndex = [show.episodes indexOfObjectPassingTest:^BOOL(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop) {
            return [episode.episodeID isEqualToString:lastEpisodeSeenID];
        }];
        
        // Migration
        if (lastEpisodeSeenIndex != NSNotFound)
        {
            LRTVDBEpisode *lastEpisodeSeen = show.episodes[lastEpisodeSeenIndex];
            
            for (LRTVDBEpisode *episode in show.episodes)
            {
                episode.seen = YES;
                
                if (episode == lastEpisodeSeen)
                {
                    break;
                }
            }
        }
        
        [show reloadActiveEpisode];
    }
    
    return show;
}

- (NSDictionary *)serialize
{
    return @{ kShowIDKey: LRNilToEmptyString(self.showID),
              kShowNameKey: LRNilToEmptyString(self.name),
              kShowOverviewKey: LRNilToEmptyString(self.overview),
              kShowAirDayKey: LRNilToEmptyString(self.airDay),
              kShowAirTimeKey: LRNilToEmptyString(self.airTime),
              kShowFanartURLKey: LRNilToEmptyString([self.fanartURL absoluteString]),
              kShowBannerURLKey: LRNilToEmptyString([self.bannerURL absoluteString]),
              kShowPosterURLKey: LRNilToEmptyString([self.posterURL absoluteString]),
              kShowPremiereDateKey: LRNilToEmptyString(self.premiereDate),
              kShowGenresKey: LRNilToEmptyString(self.genres),
              kShowActorsNamesKey: LRNilToEmptyString(self.actorsNames),
              kShowImdbIDKey: LRNilToEmptyString(self.imdbID),
              kShowNetworkKey: LRNilToEmptyString(self.network),
              kShowLanguageKey: LRNilToEmptyString(self.language),
              kShowRatingKey: LRNilToEmptyString(self.rating),
              kShowRatingCountKey: LRNilToEmptyString(self.ratingCount),
              kShowBasicStatusKey: @(self.basicStatus),
              kShowContentRatingKey : LRNilToEmptyString(self.contentRating),
              kShowRuntimeKey : LRNilToEmptyString(self.runtime),
              kShowEpisodesKey : LRNilToEmptyString([self serializeEpisodes:self.episodes]),
              kShowImagesKey : LRNilToEmptyString([self serializeImages:self.images]),
              kShowActorsKey : LRNilToEmptyString([self serializeActors:self.actors]),
            };
}

+ (NSArray *)deserializeEpisodes:(NSArray *)episodes
{
    if (!episodes) return nil;

    NSMutableArray *deserializedEpisodes = [NSMutableArray arrayWithCapacity:[episodes count]];
    
    for (NSDictionary *dictionary in episodes)
    {
        NSError *error;
        
        LRTVDBEpisode *episode = [LRTVDBEpisode deserialize:dictionary error:&error];
        
        if (episode)
        {
            [deserializedEpisodes addObject:episode];
        }
    }
    
    return [deserializedEpisodes copy];
}

- (NSArray *)serializeEpisodes:(NSArray *)episodes
{
    if (!episodes) return nil;
    
    NSMutableArray *serializedEpisodes = [NSMutableArray arrayWithCapacity:[episodes count]];
    
    for (LRTVDBEpisode *episode in episodes)
    {
        [serializedEpisodes addObject:[episode serialize]];
    }
    
    return [serializedEpisodes copy];
}

+ (NSArray *)deserializeImages:(NSArray *)images
{
    if (!images) return nil;

    NSMutableArray *deserializedImages = [NSMutableArray arrayWithCapacity:[images count]];
    
    for (NSDictionary *dictionary in images)
    {
        NSError *error;

        LRTVDBImage *image = [LRTVDBImage deserialize:dictionary error:&error];
        
        if (image)
        {
            [deserializedImages addObject:image];
        }
    }
    
    return [deserializedImages copy];
}

- (NSArray *)serializeImages:(NSArray *)images
{
    if (!images) return nil;

    NSMutableArray *serializedImages = [NSMutableArray arrayWithCapacity:[images count]];
    
    for (LRTVDBImage *image in images)
    {
        [serializedImages addObject:[image serialize]];
    }
    
    return [serializedImages copy];
}

+ (NSArray *)deserializeActors:(NSArray *)actors
{
    if (!actors) return nil;

    NSMutableArray *deserializedActors = [NSMutableArray arrayWithCapacity:[actors count]];
    
    for (NSDictionary *dictionary in actors)
    {
        NSError *error;
        
        LRTVDBActor *actor = [LRTVDBActor deserialize:dictionary error:&error];
        
        if (actor)
        {
            [deserializedActors addObject:actor];
        }
    }
    
    return [deserializedActors copy];
}

- (NSArray *)serializeActors:(NSArray *)actors
{
    if (!actors) return nil;

    NSMutableArray *serializedActors = [NSMutableArray arrayWithCapacity:[actors count]];
    
    for (LRTVDBActor *actor in actors)
    {
        [serializedActors addObject:[actor serialize]];
    }
    
    return [serializedActors copy];
}

#pragma mark - Equality methods

- (BOOL)isEqual:(id)object
{
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
