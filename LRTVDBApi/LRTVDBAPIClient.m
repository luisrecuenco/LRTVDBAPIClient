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
#import "NSData+LRTVDBAdditions.h"
#import "NSArray+LRTVDBAdditions.h"
#import "LRTVDBShow+Private.h"
#import "LRTVDBEpisode+Private.h"
#import "ZZArchive.h"
#import "ZZArchiveEntry.h"
#import "LRTVDBAPIParser.h"
#import "LRTVDBAPIClient+Private.h"
#import "NSString+LRTVDBAdditions.h"

#if !__has_feature(objc_arc)
#error "LRTVDBAPI requires ARC support."
#endif

#if DEBUG
#define LRLog(s,...) NSLog( @"\n\n------------------------------------- DEBUG -------------------------------------\n\t<%p %@:(%d)>\n\n\t%@\n---------------------------------------------------------------------------------\n\n", self, \
[[NSString stringWithUTF8String:__FUNCTION__] lastPathComponent], __LINE__, \
[NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define LRLog(s,...)
#endif

/** TVDB Base URL */
static NSString *const kLRTVDBAPIBaseURLString = @"http://www.thetvdb.com/api/";

/** Updates user defaults key */
static NSString *const kLastUpdatedDefaultsKey = @"kLastUpdatedDefaultsKey";

@interface LRTVDBAPIClient()
{
   __strong NSString *_language;
}

@property (nonatomic) NSTimeInterval lastUpdated;
@property (nonatomic) dispatch_queue_t queue;

@end

@implementation LRTVDBAPIClient

+ (LRTVDBAPIClient *)sharedClient
{
    static LRTVDBAPIClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *theTVDBAPIURL = [NSURL URLWithString:kLRTVDBAPIBaseURLString];
        sharedClient = [[LRTVDBAPIClient alloc] initWithBaseURL:theTVDBAPIURL];
    });
    
    return sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (self)
    {
        [self registerHTTPOperationClass:[AFHTTPRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/xml"];
        
        _queue = dispatch_queue_create("com.LRTVDBAPI.LRTVDBAPIClientQueue", NULL);
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
    if ([NSString isEmptyString:showName])
    {
        dispatch_async(self.queue, ^{
            completionBlock(@[], nil);
        });
        return;
    }
    
    NSString *trimmedShowName = [showName stringByTrimmingCharactersInSet:
                                 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // The url should include language=all. There are some tv shows that are only
    // in the original language (different from english). Imagine that we are
    // searching for a show whose language is spanish (es) and there's no information
    // in english about it, if we search with language=en, we won't find that tv show
    // in the xml result.
    NSString *relativePath = [NSString stringWithFormat:@"GetSeries.php?seriesname=%@&language=all",
                              [trimmedShowName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    LRLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async(self.queue, ^{
            
            NSDictionary *seriesDictionary = [responseObject toDictionary];
            LRLog(@"Data received from URL: %@\n%@", operation.request.URL, seriesDictionary);
            NSArray *shows = [[LRTVDBAPIParser parser] showsFromDictionary:seriesDictionary];
            
            completionBlock(shows, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        dispatch_async(self.queue, ^{
            completionBlock(nil, error);
        });
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

- (void)showsWithIDs:(NSArray *)showsIDs
     includeEpisodes:(BOOL)includeEpisodes
     includeArtworks:(BOOL)includeArtworks
       includeActors:(BOOL)includeActors
     completionBlock:(void (^)(NSArray *shows, NSDictionary *errorsDictionary))completionBlock
{
    if (showsIDs.count == 0)
    {
        dispatch_async(self.queue, ^{
            completionBlock(@[], nil);
        });
        return;
    }
    
    NSMutableArray *_shows = [NSMutableArray array];
    NSMutableDictionary *_errorsDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *_showsDictionary = [NSMutableDictionary dictionary];
    
    __block int numberOfFinishedShows = 0;
    
    void (^finishShowBlock)(NSString *, LRTVDBShow *, NSError *) = ^(NSString *showID, LRTVDBShow *show, NSError *error){
        
        if (error)
        {
            _errorsDictionary[showID] = error;
        }
        else if (show)
        {
            _showsDictionary[showID] = show;
        }
        
        if (++numberOfFinishedShows == showsIDs.count)
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
         includeArtworks:includeArtworks
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
    if (episodesIDs.count == 0)
    {
        dispatch_async(self.queue, ^{
            completionBlock(@[], nil);
        });
        return;
    }
    
    NSMutableArray *_episodes = [NSMutableArray array];
    NSMutableDictionary *_errorsDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *_episodesDictionary = [NSMutableDictionary dictionary];
    
    __block int numberOfFinishedEpisodes = 0;
    
    void (^finishShowBlock)(NSString *, LRTVDBEpisode *, NSError *) = ^(NSString *episodeID, LRTVDBEpisode *episode, NSError *error){
        
        if (error)
        {
            _errorsDictionary[episodeID] = error;
        }
        else if (episode)
        {
            _episodesDictionary[episodeID] = episode;
        }
        
        if (++numberOfFinishedEpisodes == episodesIDs.count)
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
    NSString *relativePath = [NSString stringWithFormat:@"%@/series/%@/default/%@/%@/%@.xml", self.apiKey, showID, seasonNumber, episodeNumber, self.language];
    
    LRLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async(self.queue, ^{
            
            NSDictionary *episodesDictionary = [responseObject toDictionary];
            LRLog(@"Data received from URL: %@\n%@", operation.request.URL, episodesDictionary);
            NSArray *episodes = [[LRTVDBAPIParser parser] episodesFromDictionary:episodesDictionary];
            
            // We know there's only on episode in the array.
            completionBlock(episodes.firstObject, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        dispatch_async(self.queue, ^{
            completionBlock(nil, error);
        });
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

#pragma mark - Artworks

- (void)artworksForShowWithID:(NSString *)showID
              completionBlock:(void (^)(NSArray *artworks, NSError *error))completionBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"%@/series/%@/banners.xml", self.apiKey, showID];
    
    LRLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async(self.queue, ^{
            
            NSDictionary *artworkDictionary = [responseObject toDictionary];
            LRLog(@"Data received from URL: %@\n%@", operation.request.URL, artworkDictionary);
            NSArray *artworks = [[LRTVDBAPIParser parser] artworksFromDictionary:artworkDictionary];
            
            completionBlock(artworks, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        dispatch_async(self.queue, ^{
            completionBlock(nil, error);
        });
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

#pragma mark - Actors

- (void)actorsForShowWithID:(NSString *)showID
            completionBlock:(void (^)(NSArray *actors, NSError *error))completionBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"%@/series/%@/actors.xml", self.apiKey, showID];
    
    LRLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async(self.queue, ^{
            
            NSDictionary *actorsDictionary = [responseObject toDictionary];
            LRLog(@"Data received from URL: %@\n%@", operation.request.URL, actorsDictionary);
            NSArray *actors = [[LRTVDBAPIParser parser] actorsFromDictionary:actorsDictionary];
            
            completionBlock(actors, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        dispatch_async(self.queue, ^{
            completionBlock(nil, error);
        });
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

#pragma mark - Updates

- (void)updateShows:(NSArray *)showsToUpdate
      checkIfNeeded:(BOOL)checkIfNeeded
     updateEpisodes:(BOOL)updateEpisodes
     updateArtworks:(BOOL)updateArtworks
       updateActors:(BOOL)updateActors
    completionBlock:(void (^)(BOOL finished))completionBlock
{
    if (showsToUpdate.count == 0)
    {
        dispatch_async(self.queue, ^{
            completionBlock(YES);
        });
        return;
    }
    
    void (^block)(NSArray *) = ^(NSArray *validShowsToUpdate) {
        
        if (validShowsToUpdate.count == 0)
        {
            completionBlock(YES);
            return;
        }

        __block BOOL updateFinishedOk = YES;
        __block int numerOfUpdatedShows = 0;
        
        void (^updateShowBlock)(LRTVDBShow *, LRTVDBShow *, NSError *) = ^(LRTVDBShow *showToUpdate, LRTVDBShow *updatedShow, NSError *error){
            
            [showToUpdate updateWithShow:updatedShow
                          updateEpisodes:updateEpisodes
                          updateArtworks:updateArtworks
                            updateActors:updateActors];
            
            if (updateFinishedOk)
            {
                updateFinishedOk = (error == nil);
            }
            
            if (++numerOfUpdatedShows == validShowsToUpdate.count)
            {
                completionBlock(updateFinishedOk);
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
            
            if ([show.language isEqualToString:LRTVDBDefaultLanguage()])
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
             includeArtworks:updateArtworks
               includeActors:updateActors
             completionBlock:^(LRTVDBShow *updatedShow, NSError *error) {
                 updateShowBlock(show, updatedShow, error);
             }];
        }
    };
    
    if (checkIfNeeded)
    {
        NSMutableArray *validShowsToUpdate = [NSMutableArray array];
        
        [self showsIDsToUpdateWithCompletionBlock:^(NSArray *showsIDs, NSError *error) {
            
            for (LRTVDBShow *show in showsToUpdate)
            {
                if ([showsIDs containsObject:show.showID])
                {
                    [validShowsToUpdate addObject:show];
                }
            }
            
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
    if (episodesToUpdate.count == 0)
    {
        dispatch_async(self.queue, ^{
            completionBlock(YES);
        });
        return;
    }
    
    void (^block)(NSArray *) = ^(NSArray *validEpisodesToUpdate) {
        
        if (validEpisodesToUpdate.count == 0)
        {
            completionBlock(YES);
            return;
        }
        
        __block BOOL updateFinishedOk = YES;
        __block int numerOfUpdatedEpisodes = 0;
        
        void (^updateEpisodeBlock)(LRTVDBEpisode *, LRTVDBEpisode *, NSError *) = ^(LRTVDBEpisode *episodeToUpdate, LRTVDBEpisode *updatedEpisode, NSError *error){
            
            [episodeToUpdate updateWithEpisode:updatedEpisode];
            
            if (updateFinishedOk)
            {
                updateFinishedOk = (error == nil);
            }
            
            if (++numerOfUpdatedEpisodes == validEpisodesToUpdate.count)
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
        NSMutableArray *validEpisodesToUpdate = [NSMutableArray array];
        
        [self episodesIDsToUpdateWithCompletionBlock:^(NSArray *episodesIDs, NSError *error) {
            
            for (LRTVDBEpisode *episode in episodesToUpdate)
            {
                if ([episodesIDs containsObject:episode.episodeID])
                {
                    [validEpisodesToUpdate addObject:episode];
                }
            }
            
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
    
    LRLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async(self.queue, ^{
            
            LRLog(@"Data received from URL: %@\n%@", operation.request.URL, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            
            NSArray *showsIDs = [[LRTVDBAPIParser parser] showsIDsFromData:responseObject];
            completionBlock(showsIDs, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        dispatch_async(self.queue, ^{
            completionBlock(nil, error);
        });
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

- (void)episodesIDsToUpdateWithCompletionBlock:(void (^)(NSArray *episodesIDs, NSError *error))completionBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"Updates.php?type=episode&time=%f", self.lastUpdated];
    
    LRLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async(self.queue, ^{
            
            LRLog(@"Data received from URL: %@\n%@", operation.request.URL, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            
            NSArray *episodesIDs = [[LRTVDBAPIParser parser] episodesIDsFromData:responseObject];
            completionBlock(episodesIDs, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        dispatch_async(self.queue, ^{
            completionBlock(nil, error);
        });
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

- (void)refreshLastUpdateTimestamp
{
    _lastUpdated = [[NSDate date] timeIntervalSince1970];
    [[NSUserDefaults standardUserDefaults] setDouble:_lastUpdated forKey:kLastUpdatedDefaultsKey];
}

#pragma mark - Private

- (void)showWithID:(NSString *)showID
          language:(NSString *)language
   includeEpisodes:(BOOL)includeEpisodes
   includeArtworks:(BOOL)includeArtworks
     includeActors:(BOOL)includeActors
   completionBlock:(void (^)(LRTVDBShow *show, NSError *error))completionBlock
{    
    BOOL shouldUseZippedVersion = [self shouldUseZippedVersionBasedOnEpisodes:includeEpisodes
                                                                     artworks:includeArtworks
                                                                       actors:includeActors];
    
    if (shouldUseZippedVersion)
    {
        [self zipVersionOfShowWithID:showID
                            language:language
                     includeEpisodes:includeEpisodes
                     includeArtworks:includeArtworks
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
 series data, artwork data and actors data.
 */
- (void)zipVersionOfShowWithID:(NSString *)showID
                      language:(NSString *)language
               includeEpisodes:(BOOL)includeEpisodes
               includeArtworks:(BOOL)includeArtworks
                 includeActors:(BOOL)includeActors
               completionBlock:(void (^)(LRTVDBShow *show, NSError *error))completionBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"%@/series/%@/all/%@.zip", self.apiKey, showID, language ?: self.language];
    
    LRLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async(self.queue, ^{
            
            ZZArchive *oldArchive = [ZZArchive archiveWithData:responseObject];
            
            ZZArchiveEntry *firstArchiveEntry = oldArchive.entries[0]; // series XML info
            ZZArchiveEntry *secondArchiveEntry = oldArchive.entries[1]; // artwork XML info
            ZZArchiveEntry *thirdArchiveEntry = oldArchive.entries[2]; // actors XML info
            
            NSDictionary *seriesDictionary = [firstArchiveEntry.data toDictionary];
            NSDictionary *artworksDictionary = [secondArchiveEntry.data toDictionary];
            NSDictionary *actorsDictionary = [thirdArchiveEntry.data toDictionary];
            
            LRLog(@"Data received from URL: %@\n%@", operation.request.URL, seriesDictionary);
            
            LRTVDBShow *show = [[LRTVDBAPIParser parser] showsFromDictionary:seriesDictionary].firstObject;
           
            if (includeEpisodes)
            {
                [show addEpisodes:[[LRTVDBAPIParser parser] episodesFromDictionary:seriesDictionary]];
            }
            
            if (includeArtworks)
            {
                [show addArtworks:[[LRTVDBAPIParser parser] artworksFromDictionary:artworksDictionary]];
            }
            
            if (includeActors)
            {
                [show addActors:[[LRTVDBAPIParser parser] actorsFromDictionary:actorsDictionary]];
            }
            
            completionBlock(show, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        dispatch_async(self.queue, ^{
            completionBlock(nil, error);
        });
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

/**
 Creates a LRTVDBShow by downloading the xml file containing only
 series data (nothing about artwork or actors).
 */
- (void)xmlVersionOfShowWithID:(NSString *)showID
                      language:(NSString *)language
               includeEpisodes:(BOOL)includeEpisodes
               completionBlock:(void (^)(LRTVDBShow *show, NSError *error))completionBlock
{
    NSString *relativePath = nil;
    
    if (includeEpisodes)
    {
        relativePath = [NSString stringWithFormat:@"%@/series/%@/all/%@.xml", self.apiKey, showID, language ?: self.language];
    }
    else
    {
        relativePath = [NSString stringWithFormat:@"%@/series/%@/%@.xml", self.apiKey, showID, language ?: self.language];
    }
    
    LRLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async(self.queue, ^{
            
            NSDictionary *seriesDictionary = [responseObject toDictionary];
            LRLog(@"Data received from URL: %@\n%@", operation.request.URL, seriesDictionary);
            LRTVDBShow *show = [[LRTVDBAPIParser parser] showsFromDictionary:seriesDictionary].firstObject;
            
            if (includeEpisodes)
            {
                [show addEpisodes:[[LRTVDBAPIParser parser] episodesFromDictionary:seriesDictionary]];
            }
            
            completionBlock(show, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        dispatch_async(self.queue, ^{
            completionBlock(nil, error);
        });
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

- (BOOL)shouldUseZippedVersionBasedOnEpisodes:(BOOL)episodes
                                     artworks:(BOOL)artworks
                                       actors:(BOOL)actors
{
    // Use zipped version whenever two normal request would be done
    // to meet the requirements for the show. Sometimes, and depending on the
    // number of episodes, the zip version is worthwhile when artworks = NO,
    // actors = NO and episodes = YES. Let's skip episode condition for now.
    return (artworks || actors);
}

- (void)episodeWithID:(NSString *)episodeID
             language:(NSString *)language
      completionBlock:(void (^)(LRTVDBEpisode *episode, NSError *error))completionBlock
{
    NSString *relativePath = [NSString stringWithFormat:@"%@/episodes/%@/%@.xml", self.apiKey, episodeID, language ?: self.language];
    
    LRLog(@"Retrieving data from URL: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath]);
    
    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        
        dispatch_async(self.queue, ^{
            
            NSDictionary *episodesDictionary = [responseObject toDictionary];
            LRLog(@"Data received from URL: %@\n%@", operation.request.URL, episodesDictionary);
            NSArray *episodes = [[LRTVDBAPIParser parser] episodesFromDictionary:episodesDictionary];
            
            // We know there's only on episode in the array.
            completionBlock(episodes.firstObject, nil);
        });
    };
    
    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        
        LRLog(@"Error when retrieving data from URL: %@ | error: %@", [kLRTVDBAPIBaseURLString stringByAppendingPathComponent:relativePath], [error localizedDescription]);
        
        dispatch_async(self.queue, ^{
            completionBlock(nil, error);
        });
    };
    
    [self getPath:relativePath parameters:nil success:successBlock failure:failureBlock];
}

#pragma mark - TVDB Language

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
    NSString *preferredLanguage = [NSLocale preferredLanguages].firstObject;
    
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
 @return A newly-initialized NSArray containing the supported TVDB API languages.
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

#pragma mark - API Key

- (NSString *)apiKey
{
    NSAssert(_apiKey != nil, @"You must provide an API key.");
    return _apiKey;
}

@end
