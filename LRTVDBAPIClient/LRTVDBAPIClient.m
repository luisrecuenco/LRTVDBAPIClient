// LRTVDBAPIClient.m
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

#import "LRTVDBAPIClient.h"
#import "AFHTTPRequestOperation.h"
#import "NSArray+LRTVDBAdditions.h"
#import "LRTVDBShow+Private.h"
#import "LRTVDBEpisode+Private.h"
#import "ZZArchive.h"
#import "ZZArchiveEntry.h"
#import "LRTVDBShowParser.h"
#import "LRTVDBAPIClient+Private.h"
#import "LRTVDBActorParser.h"
#import "LRTVDBImageParser.h"
#import "LRTVDBEpisodeParser.h"

#if !__has_feature(objc_arc)
#error "LRTVDBAPIClient requires ARC support."
#endif

#ifndef NS_BLOCKS_AVAILABLE
#error "LRTVDBAPIClient requires blocks."
#endif

#if DEBUG
#define LRTVDBAPIClientLog(s,...) NSLog( @"\n\n------------------------------------- DEBUG -------------------------------------\n\t<%p %@:(%d)>\n\n\t%@\n---------------------------------------------------------------------------------\n\n", self, \
[[NSString stringWithUTF8String:__FUNCTION__] lastPathComponent], __LINE__, \
[NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define LRTVDBAPIClientLog(s,...)
#endif

/** TVDB Base URL */
static NSString *const kLRTVDBAPIBaseURLString = @"http://www.thetvdb.com/api/";

/** Updates User Defaults Key */
static NSString *const kLastUpdatedDefaultsKey = @"kLastUpdatedDefaultsKey";

@interface LRTVDBAPIClient()
{
    __strong NSString *_language;
}

@property (nonatomic) NSTimeInterval lastUpdated;

@end

@implementation LRTVDBAPIClient

+ (LRTVDBAPIClient *)sharedClient
{
    static LRTVDBAPIClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    
    return sharedClient;
}

- (id)init
{
    return [self initWithBaseURL:[NSURL URLWithString:kLRTVDBAPIBaseURLString]];
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (self)
    {
        [self registerHTTPOperationClass:[AFHTTPRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/xml"];
        
        _lastUpdated = [[NSUserDefaults standardUserDefaults] doubleForKey:kLastUpdatedDefaultsKey];
        
        if (_lastUpdated == 0)
        {
            [self refreshLastUpdateTimestamp];
        }
    }
    
    return self;
}

#pragma mark - Shows

- (void)showsWithName:(NSString *)showName
      completionBlock:(void (^)(NSArray *shows, NSError *error))completionBlock
{    
    NSString *relativePath = LRTVDBShowsWithNameRelativePathForShow(showName);

    if (!relativePath)
    {
        completionBlock(@[], nil);
        return;
    }
    
    LRTVDBAPIClientLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
                
        if ([operation isCancelled]) return;
        
        dispatch_async([[self class] lr_sharedConcurrentQueue], ^{
            
            LRTVDBAPIClientLog(@"Data received from URL: %@\n%@", operation.request.URL, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            
            completionBlock([[LRTVDBShowParser parser] parseBasicShowInfoFromData:responseObject], nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if ([operation isCancelled]) return;

        LRTVDBAPIClientLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        completionBlock(@[], error);
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

- (void)showsWithIDs:(NSArray *)showsIDs
     includeEpisodes:(BOOL)includeEpisodes
       includeImages:(BOOL)includeImages
       includeActors:(BOOL)includeActors
     completionBlock:(void (^)(NSArray *shows, NSDictionary *errorsDictionary))completionBlock
{
    if ([showsIDs count] == 0)
    {
        completionBlock(@[], @{});
        return;
    }
    
    NSMutableArray *_shows = [NSMutableArray array];
    NSMutableDictionary *_errorsDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *_showsDictionary = [NSMutableDictionary dictionary];
    
    __block int numberOfFinishedShows = 0;
    
    void (^finishShowBlock)(NSString *, LRTVDBShow *, NSError *) = ^(NSString *showID, LRTVDBShow *show, NSError *error) {
        
        if (error)
        {
            _errorsDictionary[showID] = error;
        }
        else if (show)
        {
            _showsDictionary[showID] = show;
        }
        
        if (++numberOfFinishedShows == [showsIDs count])
        {
            // Sort results
            for (NSString *showID in showsIDs)
            {
                // An error may have arisen for the showID and
                // show could be nil. Checking on that.
                LRTVDBShow *show = _showsDictionary[showID];
                if (show)
                {
                    [_shows addObject:show];
                }
            }
            
            completionBlock([_shows copy], [_errorsDictionary copy]);
        }
    };
    
    for (NSString *showID in showsIDs)
    {
        [self showWithID:showID
                language:self.language
         includeEpisodes:includeEpisodes
           includeImages:includeImages
           includeActors:includeActors
         completionBlock:^(LRTVDBShow *show, NSError *error) {
             finishShowBlock(showID, show, error);
         }];
    }
}

#pragma mark - Episodes

- (void)episodesWithIDs:(NSArray *)episodesIDs
        completionBlock:(void (^)(NSArray *episodes, NSDictionary *errorsDictionary))completionBlock
{
    if ([episodesIDs count] == 0)
    {
        completionBlock(@[], @{});
        return;
    }
    
    NSMutableArray *_episodes = [NSMutableArray array];
    NSMutableDictionary *_errorsDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *_episodesDictionary = [NSMutableDictionary dictionary];
    
    __block int numberOfFinishedEpisodes = 0;
    
    void (^finishShowBlock)(NSString *, LRTVDBEpisode *, NSError *) = ^(NSString *episodeID, LRTVDBEpisode *episode, NSError *error) {
        
        if (error)
        {
            _errorsDictionary[episodeID] = error;
        }
        else if (episode)
        {
            _episodesDictionary[episodeID] = episode;
        }
        
        if (++numberOfFinishedEpisodes == [episodesIDs count])
        {
            // Sort results
            for (NSString *episodeID in episodesIDs)
            {
                // An error may have arisen for the showID and
                // show could be nil. Checking on that.
                LRTVDBEpisode *episode = _episodesDictionary[episodeID];
                if (episode)
                {
                    [_episodes addObject:episode];
                }
            }
            
            completionBlock([_episodes copy], [_errorsDictionary copy]);
        }
    };
    
    for (NSString *episodeID in episodesIDs)
    {
        [self episodeWithID:episodeID
                   language:self.language
            completionBlock:^(LRTVDBEpisode *episode, NSError *error) {
                finishShowBlock(episodeID, episode, error);
            }];
    }
}

- (void)episodeWithSeasonNumber:(NSNumber *)seasonNumber
                  episodeNumber:(NSNumber *)episodeNumber
                  forShowWithID:(NSString *)showID
                completionBlock:(void (^)(LRTVDBEpisode *episode, NSError *error))completionBlock
{
    NSParameterAssert(seasonNumber && episodeNumber && showID);
    
    NSString *relativePath = [NSString stringWithFormat:@"%@/series/%@/default/%@/%@/%@.xml", self.apiKey, showID, seasonNumber, episodeNumber, self.language];
    
    LRTVDBAPIClientLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async([[self class] lr_sharedConcurrentQueue], ^{
            
            LRTVDBAPIClientLog(@"Data received from URL: %@\n%@", operation.request.URL, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            
            // We know there's only on episode in the array.
            completionBlock([[[LRTVDBEpisodeParser parser] episodesFromData:responseObject] lr_firstObject], nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRTVDBAPIClientLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        completionBlock(nil, error);
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

#pragma mark - Images

- (void)imagesForShowWithID:(NSString *)showID
            completionBlock:(void (^)(NSArray *images, NSError *error))completionBlock
{
    NSParameterAssert(showID);
    
    NSString *relativePath = [NSString stringWithFormat:@"%@/series/%@/banners.xml", self.apiKey, showID];
    
    LRTVDBAPIClientLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async([[self class] lr_sharedConcurrentQueue], ^{

            LRTVDBAPIClientLog(@"Data received from URL: %@\n%@", operation.request.URL, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            
            completionBlock([[LRTVDBImageParser parser] imagesFromData:responseObject], nil);            
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRTVDBAPIClientLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        completionBlock(@[], error);
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

#pragma mark - Actors

- (void)actorsForShowWithID:(NSString *)showID
            completionBlock:(void (^)(NSArray *actors, NSError *error))completionBlock
{
    NSParameterAssert(showID);
    
    NSString *relativePath = [NSString stringWithFormat:@"%@/series/%@/actors.xml", self.apiKey, showID];
    
    LRTVDBAPIClientLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async([[self class] lr_sharedConcurrentQueue], ^{
            
            LRTVDBAPIClientLog(@"Data received from URL: %@\n%@", operation.request.URL, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
                        
            completionBlock([[LRTVDBActorParser parser] actorsFromData:responseObject], nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRTVDBAPIClientLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        completionBlock(@[], error);
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

#pragma mark - Updates

- (void)updateShows:(NSArray *)showsToUpdate
      checkIfNeeded:(BOOL)checkIfNeeded
     updateEpisodes:(BOOL)updateEpisodes
       updateImages:(BOOL)updateImages
       updateActors:(BOOL)updateActors
     replaceArtwork:(BOOL)replaceArtwork
    completionBlock:(void (^)(BOOL finished))completionBlock
{
    if ([showsToUpdate count] == 0)
    {
        if (completionBlock) completionBlock(YES);
        return;
    }
    
    void (^block)(NSArray *) = ^(NSArray *validShowsToUpdate) {
        
        if ([validShowsToUpdate count] == 0)
        {
            if (completionBlock) completionBlock(YES);
            return;
        }
        
        __block BOOL updateFinishedOk = YES;
        __block int numerOfUpdatedShows = 0;
        
        void (^updateShowBlock)(LRTVDBShow *, LRTVDBShow *, NSError *) = ^(LRTVDBShow *showToUpdate, LRTVDBShow *updatedShow, NSError *error) {
            
            [showToUpdate updateWithShow:updatedShow
                          updateEpisodes:updateEpisodes
                            updateImages:updateImages
                            updateActors:updateActors
                          replaceArtwork:replaceArtwork];
            
            if (updateFinishedOk)
            {
                updateFinishedOk = (error == nil);
            }
            
            if (++numerOfUpdatedShows == [validShowsToUpdate count])
            {
                if (completionBlock) completionBlock(YES);
            }
        };
        
        for (LRTVDBShow *show in validShowsToUpdate)
        {
            // It's very likely that, after using showsWithName:completionBlock,
            // we don't get an instance of the show in our preferred language. That
            // doesn't necessarily mean that the show isn't translated, but theTVDB
            // is not returning the correct information. Let's use the correct language
            // for this very case.
            NSString *correctLanguage = nil;
            
            BOOL shouldForceEnglishMetadata = self.forceEnglishMetadata && [show.availableLanguages containsObject:LRTVDBDefaultLanguage()];
            
            if ([show.language isEqualToString:LRTVDBDefaultLanguage()] || shouldForceEnglishMetadata)
            {
                correctLanguage = self.language;
            }
            else
            {
                correctLanguage = show.language;
            }
            
            [self showWithID:show.showID
                    language:correctLanguage
             includeEpisodes:updateEpisodes
               includeImages:updateImages
               includeActors:updateActors
             completionBlock:^(LRTVDBShow *updatedShow, NSError *error) {
                 updateShowBlock(show, updatedShow, error);
             }];
        }
    };
    
    if (checkIfNeeded)
    {
        [self showsIDsToUpdateWithCompletionBlock:^(NSArray *showsIDs, NSError *error) {
            
            NSIndexSet *indexSet = [showsToUpdate indexesOfObjectsPassingTest:^BOOL(LRTVDBShow *show, NSUInteger idx, BOOL *stop) {
                return [showsIDs containsObject:show.showID];
            }];
            
            NSArray *validShowsToUpdate = [showsToUpdate objectsAtIndexes:indexSet];
            block(validShowsToUpdate);
        }];
    }
    else
    {
        block(showsToUpdate);
    }
}

- (void)updateEpisodes:(NSArray *)episodesToUpdate
         checkIfNeeded:(BOOL)checkIfNeeded
       completionBlock:(void (^)(BOOL finished))completionBlock
{
    if ([episodesToUpdate count] == 0)
    {
        if (completionBlock) completionBlock(YES);
        return;
    }
    
    void (^block)(NSArray *) = ^(NSArray *validEpisodesToUpdate) {
        
        if ([validEpisodesToUpdate count] == 0)
        {
            completionBlock(YES);
            return;
        }
        
        __block BOOL updateFinishedOk = YES;
        __block int numerOfUpdatedEpisodes = 0;
        
        void (^updateEpisodeBlock)(LRTVDBEpisode *, LRTVDBEpisode *, NSError *) = ^(LRTVDBEpisode *episodeToUpdate, LRTVDBEpisode *updatedEpisode, NSError *error) {
            
            [episodeToUpdate updateWithEpisode:updatedEpisode];
            
            if (updateFinishedOk)
            {
                updateFinishedOk = (error == nil);
            }
            
            if (++numerOfUpdatedEpisodes == [validEpisodesToUpdate count])
            {
                completionBlock(updateFinishedOk);
            }
        };
        
        for (LRTVDBEpisode *episode in validEpisodesToUpdate)
        {
            [self episodeWithID:episode.episodeID
                       language:episode.language
                completionBlock:^(LRTVDBEpisode *updatedEpisode, NSError *error) {
                    updateEpisodeBlock(episode, updatedEpisode, error);
                }];
        }
    };
    
    if (checkIfNeeded)
    {
        [self episodesIDsToUpdateWithCompletionBlock:^(NSArray *episodesIDs, NSError *error) {
            
            NSIndexSet *indexSet = [episodesToUpdate indexesOfObjectsPassingTest:^BOOL(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop) {
                return [episodesIDs containsObject:episode.episodeID];
            }];
            
            NSArray *validEpisodesToUpdate = [episodesToUpdate objectsAtIndexes:indexSet];
            block(validEpisodesToUpdate);
        }];
    }
    else
    {
        block(episodesToUpdate);
    }
}

- (void)showsIDsToUpdateWithCompletionBlock:(void (^)(NSArray *showsIDs, NSError *error))completionBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"Updates.php?type=series&time=%f", self.lastUpdated];
    
    LRTVDBAPIClientLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async([[self class] lr_sharedConcurrentQueue], ^{
            
            LRTVDBAPIClientLog(@"Data received from URL: %@\n%@", operation.request.URL, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            
            NSArray *showsIDs = [[LRTVDBShowParser parser] showsIDsFromData:responseObject];
            completionBlock(showsIDs, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRTVDBAPIClientLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        completionBlock(@[], error);
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

- (void)episodesIDsToUpdateWithCompletionBlock:(void (^)(NSArray *episodesIDs, NSError *error))completionBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"Updates.php?type=episode&time=%f", self.lastUpdated];
    
    LRTVDBAPIClientLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async([[self class] lr_sharedConcurrentQueue], ^{
            
            LRTVDBAPIClientLog(@"Data received from URL: %@\n%@", operation.request.URL, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            
            completionBlock([[LRTVDBEpisodeParser parser] episodesIDsFromData:responseObject], nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRTVDBAPIClientLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        completionBlock(@[], error);
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

- (void)refreshLastUpdateTimestamp
{
    _lastUpdated = [[NSDate date] timeIntervalSince1970];
    [[NSUserDefaults standardUserDefaults] setDouble:_lastUpdated forKey:kLastUpdatedDefaultsKey];
}

#pragma mark - Cancel requests

- (void)cancelShowsWithNameRequest:(NSString *)showName
{
    NSString *relativePath = LRTVDBShowsWithNameRelativePathForShow(showName);
    
    [self cancelAllHTTPOperationsWithMethod:@"GET"
                                       path:relativePath];
}

- (void)cancelShowsWithIDsRequests:(NSArray *)showsIDs
                   includeEpisodes:(BOOL)includeEpisodes
                     includeImages:(BOOL)includeImages
                     includeActors:(BOOL)includeActors
{
    for (NSString *showID in showsIDs)
    {
        NSString *relativePath = [self relativePathForShowWithID:showID
                                                 includeEpisodes:includeEpisodes
                                                   includeImages:includeImages
                                                   includeActors:includeActors
                                                        language:self.language];
        
        [self cancelAllHTTPOperationsWithMethod:@"GET"
                                           path:relativePath];
    }
}

- (void)cancelUpdateOfShowsRequests:(NSArray *)showsToCancel
                     updateEpisodes:(BOOL)updateEpisodes
                       updateImages:(BOOL)updateImages
                       updateActors:(BOOL)updateActors
{
    for (LRTVDBShow *show in showsToCancel)
    {
        NSString *correctLanguage = nil;
        
        if ([show.language isEqualToString:LRTVDBDefaultLanguage()] || self.forceEnglishMetadata)
        {
            correctLanguage = self.language;
        }
        else
        {
            correctLanguage = show.language;
        }
        
        NSString *relativePath = [self relativePathForShowWithID:show.showID
                                                 includeEpisodes:updateEpisodes
                                                   includeImages:updateImages
                                                   includeActors:updateActors
                                                        language:correctLanguage];
        
        [self cancelAllHTTPOperationsWithMethod:@"GET"
                                           path:relativePath];
    }
}

- (void)cancelAllTVDBAPIClientRequests
{
    [self.operationQueue cancelAllOperations];
}

#pragma mark - Private

/**
 Creates a LRTVDBShow by downloading the zip or xml file containing the
 series, images and actors data.
 */
- (void)showWithID:(NSString *)showID
          language:(NSString *)language
   includeEpisodes:(BOOL)includeEpisodes
     includeImages:(BOOL)includeImages
     includeActors:(BOOL)includeActors
   completionBlock:(void (^)(LRTVDBShow *show, NSError *error))completionBlock
{
    NSParameterAssert(showID);
    
    BOOL shouldUseZippedVersion = [self shouldUseZippedVersionBasedOnEpisodes:includeEpisodes
                                                                       images:includeImages
                                                                       actors:includeActors];
    
    if (shouldUseZippedVersion)
    {
        [self zipVersionOfShowWithID:showID
                            language:language
                     includeEpisodes:includeEpisodes
                       includeImages:includeImages
                       includeActors:includeActors
                     completionBlock:completionBlock];
    }
    else
    {
        [self xmlVersionOfShowWithID:showID
                            language:language
                     includeEpisodes:includeEpisodes
                     completionBlock:completionBlock];
    }
}

/**
 Creates a LRTVDBShow by downloading the zip file containing the
 series, images and actors data.
 */
- (void)zipVersionOfShowWithID:(NSString *)showID
                      language:(NSString *)language
               includeEpisodes:(BOOL)includeEpisodes
                 includeImages:(BOOL)includeImages
                 includeActors:(BOOL)includeActors
               completionBlock:(void (^)(LRTVDBShow *show, NSError *error))completionBlock
{
    NSParameterAssert(showID);
    
    NSString *relativePath = [self relativePathForShowWithID:showID
                                             includeEpisodes:includeEpisodes
                                               includeImages:includeImages
                                               includeActors:includeActors
                                                    language:language];
    
    LRTVDBAPIClientLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async([[self class] lr_sharedConcurrentQueue], ^{
            
            LRTVDBShow *show = nil;
            
            if (responseObject)
            {
                ZZArchive *oldArchive = [ZZArchive archiveWithData:responseObject];
                
                // series XML info
                ZZArchiveEntry *firstArchiveEntry = [oldArchive.entries count] > 0 ?
                oldArchive.entries[0] : nil;
                // images XML info
                ZZArchiveEntry *secondArchiveEntry = [oldArchive.entries count] > 1 ?
                oldArchive.entries[1] : nil;
                // actors XML info
                ZZArchiveEntry *thirdArchiveEntry = [oldArchive.entries count] > 2 ?
                oldArchive.entries[2] : nil;
                
                LRTVDBAPIClientLog(@"Data received from URL: %@\n%@", operation.request.URL, [[NSString alloc] initWithData:firstArchiveEntry.data encoding:NSUTF8StringEncoding]);
                
                // We know there's only one
                show = [[[LRTVDBShowParser parser] parseShowInfoFromData:firstArchiveEntry.data] lr_firstObject];
                
                if (includeEpisodes)
                {
                    [show addEpisodes:[[LRTVDBEpisodeParser parser] episodesFromData:firstArchiveEntry.data]];
                }
                
                if (includeImages)
                {
                    [show addImages:[[LRTVDBImageParser parser] imagesFromData:secondArchiveEntry.data]];
                }
                
                if (includeActors)
                {
                    [show addActors:[[LRTVDBActorParser parser] actorsFromData:thirdArchiveEntry.data]];
                }
            }
            
            completionBlock(show, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRTVDBAPIClientLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        completionBlock(nil, error);
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

/**
 Creates a LRTVDBShow by downloading the xml file containing only
 series data (nothing about images or actors).
 */
- (void)xmlVersionOfShowWithID:(NSString *)showID
                      language:(NSString *)language
               includeEpisodes:(BOOL)includeEpisodes
               completionBlock:(void (^)(LRTVDBShow *show, NSError *error))completionBlock
{
    NSParameterAssert(showID);
    
    NSString *relativePath = [self relativePathForShowWithID:showID
                                             includeEpisodes:includeEpisodes
                                               includeImages:NO
                                               includeActors:NO
                                                    language:language];
    
    LRTVDBAPIClientLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async([[self class] lr_sharedConcurrentQueue], ^{
            
            LRTVDBAPIClientLog(@"Data received from URL: %@\n%@", operation.request.URL, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            
            // We know there's only one
            LRTVDBShow *show = [[[LRTVDBShowParser parser] parseShowInfoFromData:responseObject] lr_firstObject];
            
            if (includeEpisodes)
            {                                
                [show addEpisodes:[[LRTVDBEpisodeParser parser] episodesFromData:responseObject]];
            }
            
            completionBlock(show, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRTVDBAPIClientLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        completionBlock(nil, error);
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

- (BOOL)shouldUseZippedVersionBasedOnEpisodes:(BOOL)episodes
                                       images:(BOOL)images
                                       actors:(BOOL)actors
{
    // From http://thetvdb.com/wiki/index.php/Programmers_API:
    // "Please avoid making more API calls than are necessary to retrieve the information you need.
    // Each series has a zipped XML file that contains all of the series and episode data for that
    // series. If your program has the technical capability of handling these files, please make an
    // attempt to use them since they'll be mirrored by more servers and will reduce bandwidth for
    // both the server and clients".
    
    // Use zipped version if:
    // 1 - images = YES || actors = YES (Two request would be done to meet the requirements).
    // 2 - episodes = YES (most of the times, this means that the xml file is bigger than the zip file).
    return episodes || images || actors;
}

- (void)episodeWithID:(NSString *)episodeID
             language:(NSString *)language
      completionBlock:(void (^)(LRTVDBEpisode *episode, NSError *error))completionBlock
{
    NSParameterAssert(episodeID);
    
    NSString *relativePath = [NSString stringWithFormat:@"%@/episodes/%@/%@.xml", self.apiKey, episodeID, language ?: self.language];
    
    LRTVDBAPIClientLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async([[self class] lr_sharedConcurrentQueue], ^{
            
            LRTVDBAPIClientLog(@"Data received from URL: %@\n%@", operation.request.URL, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            
            // We know there's only on episode in the array.
            completionBlock([[[LRTVDBEpisodeParser parser] episodesFromData:responseObject] lr_firstObject], nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRTVDBAPIClientLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        completionBlock(nil, error);
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

#pragma mark - TVDB Language

- (void)setForceEnglishMetadata:(BOOL)forceEnglishMetadata
{
    _forceEnglishMetadata = forceEnglishMetadata;
    
    if (forceEnglishMetadata)
    {
        self.language = LRTVDBDefaultLanguage();
    }
    else
    {
        self.language = nil;
    }    
}

- (NSString *)language
{
    if (_language == nil)
    {
        _language = [[self preferredLanguage] copy];
    }
    return _language;
}

- (void)setLanguage:(NSString *)language
{
    if ([LRTVDBLanguages() containsObject:language])
    {
        _language = [language copy];
    }
    else
    {
        _language = [[self preferredLanguage] copy];
    }
}

- (NSString *)preferredLanguage
{
    NSString *preferredLanguage = [[NSLocale preferredLanguages] lr_firstObject];
    
    if ([LRTVDBLanguages() containsObject:preferredLanguage])
    {
        return preferredLanguage;
    }
    else
    {
        return LRTVDBDefaultLanguage();
    }
}

/**
 @return NSArray containing the supported TVDB API languages.
 @discussion TVDB languages are very unlikely to change. That's the reason not to
 make this method asynchronous and make the logic around language handling quite
 more complex. The ideal solution would be getting the languages from the
 following URL: http://www.thetvdb.com/api/74204F775D9D3C87/languages.xml
 */
static NSArray *LRTVDBLanguages(void)
{
    static NSArray *languages = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        languages = @[@"da", @"fi", @"nl", @"de", @"it", @"es", @"fr", @"pl", @"hu", @"el", @"tr", @"ru", @"he", @"ja", @"pt", @"zh", @"cs", @"sl", @"hr", @"ko", @"en", @"sv", @"no"];
    });
    
    return languages;
}

/**
 @return NSDictionary @{ languageCode : languageID } used to build the
 show URL.
 @see LRTVDBURLForShow(show) method.
 */
static NSDictionary *LRTVDBLanguageCodes(void)
{
    static NSDictionary *languageCodes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
       languageCodes = @{ @"el" : @"20",
                          @"en" : @"7",
                          @"zh" : @"27",
                          @"it" : @"15",
                          @"cs" : @"28",
                          @"es" : @"16",
                          @"ru" : @"22",
                          @"nl" : @"13",
                          @"pt" : @"26",
                          @"no" : @"9",
                          @"tr" : @"21",
                          @"pl" : @"18",
                          @"fr" : @"17",
                          @"hr" : @"31",
                          @"de" : @"14",
                          @"da" : @"10",
                          @"fi" : @"11",
                          @"hu" : @"19",
                          @"ja" : @"25",
                          @"he" : @"24",
                          @"ko" : @"32",
                          @"sv" : @"8",
                          @"sl" : @"30",
                        };
    });
    
    return languageCodes;
}

#pragma mark - Shows With Name URL

static NSString *LRTVDBShowsWithNameRelativePathForShow(NSString *showName)
{
    NSString *trimmedShowName = [showName stringByTrimmingCharactersInSet:
                                 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([trimmedShowName length] == 0) return nil;
    
    // The url should include language=all to allow the user to search
    // for a TV Show in his own language.
    return [NSString stringWithFormat:@"GetSeries.php?seriesname=%@&language=all",
            [trimmedShowName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark - Shows With IDs URL

- (NSString *)relativePathForShowWithID:(NSString *)showID
                        includeEpisodes:(BOOL)includeEpisodes
                          includeImages:(BOOL)includeImages
                          includeActors:(BOOL)includeActors
                               language:(NSString *)language
{
    BOOL shouldUseZippedVersion = [self shouldUseZippedVersionBasedOnEpisodes:includeEpisodes
                                                                       images:includeImages
                                                                       actors:includeActors];
    if (shouldUseZippedVersion)
    {
        return [NSString stringWithFormat:@"%@/series/%@/all/%@.zip",
                self.apiKey, showID, language ?: self.language];
    }
    else if (includeEpisodes)
    {
        return [NSString stringWithFormat:@"%@/series/%@/all/%@.xml",
                self.apiKey, showID, language ?: self.language];
    }
    else
    {
        return [NSString stringWithFormat:@"%@/series/%@/%@.xml",
                self.apiKey, showID, language ?: self.language];
    }
}

#pragma mark - TVDB Show URL

/** TVDB show URL */
static NSString *const kLRTVDBAPIShowURLString = @"http://thetvdb.com/?tab=series&id=%@&lid=%@";

NSURL *LRTVDBURLForShow(LRTVDBShow *show)
{
    NSCParameterAssert(show);
    
    NSString *urlString = [NSString stringWithFormat:kLRTVDBAPIShowURLString,
                           show.showID, LRTVDBLanguageCodes()[show.language]];
    return [NSURL URLWithString:urlString];
}

#pragma mark - API Key

static NSString *const kLRTVDBDefaultAPIKey = @"0629B785CE550C8D";

- (NSString *)apiKey
{
    if (_apiKey == nil)
    {
        _apiKey = [kLRTVDBDefaultAPIKey copy];
    }
    return _apiKey;
}

#pragma mark - Shared Concurrent Queue

+ (dispatch_queue_t)lr_sharedConcurrentQueue
{
    static dispatch_queue_t sConcurrentQueue = NULL;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sConcurrentQueue = dispatch_queue_create("com.LRTVDBAPIClient.LRTVDBAPIClientConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return sConcurrentQueue;
}

@end
