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

#import "LRTVDBActor.h"
#import "LRTVDBEpisode+Private.h"
#import "LRTVDBImage.h"
#import "LRTVDBShow+Private.h"
#import "LRTVDBShow.h"
#import "NSDate+LRTVDBAdditions.h"

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
    .fanartURL = @"fanartURL",
    .posterURL = @"posterURL",
    .lastEpisode = @"lastEpisode",
    .lastEpisodeSeen = @"lastEpisodeSeen",
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
        
        LRTVDBEpisode *lastEpisodeSeen = self.lastEpisodeSeen;

        _episodes = [[self mergeObjects:episodes
                            withObjects:_episodes
                        comparisonBlock:LRTVDBEpisodeComparator] copy];
        
        if (lastEpisodeSeen)
        {
            NSUInteger lastEpisodeSeenIndex = [_episodes indexOfObjectPassingTest:^BOOL(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop) {
                return [episode.episodeID isEqualToString:lastEpisodeSeen.episodeID];
            }];
            
            if (lastEpisodeSeenIndex != NSNotFound)
            {
                self.lastEpisodeSeen = _episodes[lastEpisodeSeenIndex];
            }
        }
        
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
        self.lastEpisode = _episodes.lastObject;
    }
    else
    {
        __block BOOL lastEpisodeSet = NO;
        
        NSDate *fromDate = [[NSDate date] dateByIgnoringTime];
        
        void (^block)(LRTVDBEpisode *, NSUInteger, BOOL *) = ^(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop) {
            
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
    NSUInteger nextEpisodeIndex = [_episodes indexOfObjectIdenticalTo:self.lastEpisode] + 1;
    BOOL notValidNextEpisode = nextEpisodeIndex >= _episodes.count ||
                               [_episodes[nextEpisodeIndex] airedDate] == nil;
    self.nextEpisode = notValidNextEpisode ? nil : (_episodes)[nextEpisodeIndex];
    
    // Days to next episode
    self.daysToNextEpisode = [self daysToEpisode:self.nextEpisode];
    
    // Number of seasons
    self.numberOfSeasons = [_episodes.lastObject seasonNumber];
    
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
    
    for (LRTVDBEpisode *episode in _episodes)
    {
        NSMutableArray *episodesForSeason = [newSeasonToEpisodesDictionary[episode.seasonNumber] mutableCopy];
        if (episodesForSeason == nil)
        {
            episodesForSeason = [NSMutableArray array];
        }
        
        [episodesForSeason addObject:episode];
        
        newSeasonToEpisodesDictionary[episode.seasonNumber] = [episodesForSeason copy];
    }
    
    self.seasonToEpisodesDictionary = newSeasonToEpisodesDictionary;
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
    return (self.seasonToEpisodesDictionary)[seasonNumber] ? : @[];
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

#pragma mark - Update show

- (void)updateWithShow:(LRTVDBShow *)updatedShow
        updateEpisodes:(BOOL)updateEpisodes
          updateImages:(BOOL)updateImages
          updateActors:(BOOL)updateActors
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
    self.bannerURL = self.bannerURL ? : updatedShow.bannerURL;
    self.fanartURL = self.fanartURL ? : updatedShow.fanartURL;
    self.posterURL = self.posterURL ? : updatedShow.posterURL;
    self.premiereDate = updatedShow.premiereDate;
    self.rating = updatedShow.rating;
    self.ratingCount = updatedShow.ratingCount;

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

#pragma mark - LRTVDBSerializableModelProtocol

+ (LRTVDBShow *)deserialize:(NSDictionary *)dictionary
{
    LRTVDBShow *show = [[LRTVDBShow alloc] init];
    
    show.showID = LREmptyStringToNil(dictionary[kShowIDKey]);
    show.name = LREmptyStringToNil(dictionary[kShowNameKey]);
    show.overview = LREmptyStringToNil(dictionary[kShowOverviewKey]);
    show.fanartURL = [NSURL URLWithString:LREmptyStringToNil(dictionary[kShowFanartURLKey])];
    show.bannerURL = [NSURL URLWithString:LREmptyStringToNil(dictionary[kShowBannerURLKey])];
    show.posterURL = [NSURL URLWithString:LREmptyStringToNil(dictionary[kShowPosterURLKey])];
    show.airTime = LREmptyStringToNil(dictionary[kShowAirTimeKey]);
    show.airDay = LREmptyStringToNil(dictionary[kShowAirDayKey]);
    show.premiereDate = LREmptyStringToNil(dictionary[kShowPremiereDateKey]);
    show.genres = LREmptyStringToNil(dictionary[kShowGenresKey]);
    show.actorsNames = LREmptyStringToNil(dictionary[kShowActorsNamesKey]);
    show.imdbID = LREmptyStringToNil(dictionary[kShowImdbIDKey]);
    show.network = LREmptyStringToNil(dictionary[kShowNetworkKey]);
    show.language = LREmptyStringToNil(dictionary[kShowLanguageKey]);
    show.rating = LREmptyStringToNil(dictionary[kShowRatingKey]);
    show.ratingCount = LREmptyStringToNil(dictionary[kShowRatingCountKey]);
    show.basicStatus = [LREmptyStringToNil(dictionary[kShowBasicStatusKey]) integerValue];
    show.contentRating = LREmptyStringToNil(dictionary[kShowContentRatingKey]);
    show.runtime = LREmptyStringToNil(dictionary[kShowRuntimeKey]);
    
    NSString *lastEpisodeSeenID = LREmptyStringToNil(dictionary[kShowLastEpisodeSeenKey]);
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
        
        if (lastEpisodeSeenIndex != NSNotFound)
        {
            show.lastEpisodeSeen = show.episodes[lastEpisodeSeenIndex];
        }
    }
    
    return show;
}

- (NSDictionary *)serialize
{
    NSMutableDictionary *dictionary = [@{ kShowIDKey: LRNilToEmptyString(self.showID),
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
                                       kShowBasicStatusKey: LRNilToEmptyString(@(self.basicStatus)),
                                       kShowContentRatingKey : LRNilToEmptyString(self.contentRating),
                                       kShowRuntimeKey : LRNilToEmptyString(self.runtime)
                                       } mutableCopy];
    
    NSString *lastEpisodeSeenID = self.lastEpisodeSeen.episodeID;
    
    if (lastEpisodeSeenID) dictionary[kShowLastEpisodeSeenKey] = self.lastEpisodeSeen.episodeID;
    
    NSArray *serializedEpisodes = [self serializeEpisodes:self.episodes];
    
    if (serializedEpisodes) dictionary[kShowEpisodesKey] = serializedEpisodes;
    
    NSArray *serializedImages = [self serializeImages:self.images];
    
    if (serializedImages)  dictionary[kShowImagesKey] = serializedImages;
    
    NSArray *serializedActors = [self serializeActors:self.actors];
    
    if (serializedActors) dictionary[kShowActorsKey] = serializedActors;
    
    return [dictionary copy];
}

+ (NSArray *)deserializeEpisodes:(NSArray *)episodes
{
    if (!episodes) return nil;

    NSMutableArray *deserializedEpisodes = [NSMutableArray arrayWithCapacity:[episodes count]];
    
    for (NSDictionary *dictionary in episodes)
    {
        [deserializedEpisodes addObject:[LRTVDBEpisode deserialize:dictionary]];
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
        [deserializedImages addObject:[LRTVDBImage deserialize:dictionary]];
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
        [deserializedActors addObject:[LRTVDBActor deserialize:dictionary]];
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
