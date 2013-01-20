// LRTVDBAPIClientTests.m
//
// Copyright (c) 2013 Luis Recuenco
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

#import "LRTVDBAPIClientTests.h"
#import "LRTVDBAPIClient.h"
#import "LRTVDBShow.h"
#import "LRTVDBEpisode.h"
#import "LRTVDBImage.h"
#import "LRTVDBActor.h"

@implementation LRTVDBAPIClientTests

- (void)setUp
{
    [super setUp];
    
    [LRTVDBAPIClient sharedClient].language = nil;
    [LRTVDBAPIClient sharedClient].includeSpecials = NO;
}

#pragma mark - Shows With Name

- (void)testShowsWithNameNoResults
{
    [self showsWithname:@"dsjklafdlsñfñadsñfjñaklñds"
        completionBlock:^(NSArray *shows, NSError *error) {
            
            // Error can be nil or not, but shows will always be empty.
            STAssertEqualObjects(shows, @[], @"Shows array must be empty");
        }];
}

- (void)testShowsWithNameEmptyQuery
{
    [self showsWithname:@"      "
        completionBlock:^(NSArray *shows, NSError *error) {
            
            STAssertEqualObjects(shows, @[], @"Shows array must be empty");
            STAssertNil(error, @"Error must be nil");
        }];
}

- (void)testShowsWithNameNullQuery
{
    [self showsWithname:nil
        completionBlock:^(NSArray *shows, NSError *error) {
            
            STAssertEqualObjects(shows, @[], @"Shows array must be empty");
            STAssertNil(error, @"Error must be nil");
        }];
}

- (void)testShowsWithNameNotEnglishShow
{
    [self showsWithname:@"Keine Gnade für Dad"
        completionBlock:^(NSArray *shows, NSError *error) {
            
            if ([self showsWithNameBasicChecksWithShows:shows andError:error]) return;
            
            STAssertEqualObjects([shows[0] language], @"de", @"Language must be German");
        }];
}

- (void)testShowsWithNameCorrectLanguage
{
    [LRTVDBAPIClient sharedClient].language = @"es";
    
    [self showsWithname:@"Fringe"
        completionBlock:^(NSArray *shows, NSError *error) {
            
            if ([self showsWithNameBasicChecksWithShows:shows andError:error]) return;
            
            STAssertEqualObjects([shows[0] language], @"es", @"Language must be Spanish");
        }];
}

- (void)testShowsWithNameRemoveDuplicates
{
    [self showsWithname:@"Game of thrones"
        completionBlock:^(NSArray *shows, NSError *error) {
            
            if ([self showsWithNameBasicChecksWithShows:shows andError:error]) return;
            
            STAssertTrue([shows count] == 1, @"Shows array count must be 1");
        }];
}

- (void)testShowsWithNameBasicProperties
{
    [self showsWithname:@"Fringe"
        completionBlock:^(NSArray *shows, NSError *error) {
            
            if ([self showsWithNameBasicChecksWithShows:shows andError:error]) return;
            
            [self checkBasicPropertiesOfShow:shows[0]];
        }];
}

#pragma mark - Shows With IDs

- (void)testShowsWithIDsNullID
{
    [self showsWithIDs:nil
       includeEpisodes:YES
         includeImages:YES
         includeActors:YES
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           STAssertEqualObjects(shows, @[], @"Shows array must be empty");
           STAssertEqualObjects(errorsDictionary, @{}, @"Error dictionary must be empty");
       }];
}

- (void)testShowsWithIDsEmptyIDs
{
    [self showsWithIDs:@[]
       includeEpisodes:YES
         includeImages:YES
         includeActors:YES
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           STAssertEqualObjects(shows, @[], @"Shows array must be empty");
           STAssertEqualObjects(errorsDictionary, @{}, @"Error dictionary must be empty");
       }];
}

- (void)testShowsWithIDsSameIDsSameOrder
{
    NSArray *showsIDs = @[@"82066", @"121361", @"80379", @"75760"];
    
    [self showsWithIDs:showsIDs
       includeEpisodes:NO
         includeImages:NO
         includeActors:NO
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           [self checkObjects:shows ofClass:[LRTVDBShow class]];
           
           NSMutableArray *mutableShowsIDs = [showsIDs mutableCopy];
           
           [showsIDs enumerateObjectsUsingBlock:^(NSString *showID, NSUInteger idx, BOOL *stop) {
               
               if (errorsDictionary[showID])
               {
                   [mutableShowsIDs removeObject:showID];
               }
           }];
           
           STAssertTrue([mutableShowsIDs count] == [shows count], @"Must be equal");
           
           [shows enumerateObjectsUsingBlock:^(LRTVDBShow *show, NSUInteger idx, BOOL *stop) {
               
               STAssertEqualObjects(show.showID, mutableShowsIDs[idx], @"Shows ids must be the same");
           }];
       }];
}

- (void)testShowsWithIDsWrongShowID
{
    NSArray *showsIDs = @[@"82066", @"jklsdjalfksd"]; // one valid, one not valid
    
    [self showsWithIDs:showsIDs
       includeEpisodes:NO
         includeImages:NO
         includeActors:NO
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           [self checkObjects:shows ofClass:[LRTVDBShow class]];
           
           if (errorsDictionary[@"82066"] == nil)
           {
               STAssertTrue([shows count] == 1, @"We must have one valid result");
               STAssertEqualObjects([shows[0] showID], showsIDs[0], @"Shows IDs must be the same");
           }
           else
           {
               STAssertEqualObjects(shows, @[], @"We must have zero results");
           }
           
           STAssertNotNil(errorsDictionary[showsIDs[1]], @"Must be an error 404");
       }];
}

- (void)testShowsWithIDsFullInformation
{
    [self showsWithIDs:@[@"121361"]
       includeEpisodes:YES
         includeImages:NO
         includeActors:NO
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           if ([self showsWithIDsBasicCheckWithID:@"121361"
                                            shows:shows
                                 errorsDictionary:errorsDictionary]) return;
           
           [self checkBasicPropertiesOfShow:shows[0]];
           [self checkAdvancedPropertiesOfShow:shows[0]];
       }];
}

- (void)testShowsWithIDsCheckRelationships
{
    // No relationships
    [self showsWithIDs:@[@"80379"]
       includeEpisodes:NO
         includeImages:NO
         includeActors:NO
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           if ([self showsWithIDsBasicCheckWithID:@"80379"
                                            shows:shows
                                 errorsDictionary:errorsDictionary]) return;
           
           STAssertNil([shows[0] episodes], @"Episodes must be nil");
           STAssertNil([shows[0] images], @"Images must be nil");
           STAssertNil([shows[0] actors], @"Actors must be nil");
       }];
    
    // All relationships
    [self showsWithIDs:@[@"75760"]
       includeEpisodes:YES
         includeImages:YES
         includeActors:YES
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           if ([self showsWithIDsBasicCheckWithID:@"75760"
                                            shows:shows
                                 errorsDictionary:errorsDictionary]) return;
           
           STAssertNotNil([shows[0] episodes], @"Episodes can't be nil");
           [self checkObjects:[shows[0] episodes] ofClass:[LRTVDBEpisode class]];
           
           STAssertNotNil([shows[0] images], @"Images can't be nil");
           [self checkObjects:[shows[0] images] ofClass:[LRTVDBImage class]];
           
           STAssertNotNil([shows[0] actors], @"Actors can't be nil");
           [self checkObjects:[shows[0] actors] ofClass:[LRTVDBActor class]];
       }];
    
    // Not all relationships
    [self showsWithIDs:@[@"121361"]
       includeEpisodes:YES
         includeImages:NO
         includeActors:YES
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           if ([self showsWithIDsBasicCheckWithID:@"121361"
                                            shows:shows
                                 errorsDictionary:errorsDictionary]) return;
           
           STAssertNotNil([shows[0] episodes], @"Episodes can't be nil");
           STAssertNil([shows[0] images], @"Images must be nil");
           STAssertNotNil([shows[0] actors], @"Actors can't be nil");
       }];
    
    [self showsWithIDs:@[@"82066"]
       includeEpisodes:YES
         includeImages:YES
         includeActors:NO
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           if ([self showsWithIDsBasicCheckWithID:@"82066"
                                            shows:shows
                                 errorsDictionary:errorsDictionary]) return;
           
           STAssertNotNil([shows[0] episodes], @"Episodes can't be nil");
           STAssertNotNil([shows[0] images], @"Images can't be nil");
           STAssertNil([shows[0] actors], @"Actors must be nil");
       }];
    
    
    [self showsWithIDs:@[@"75760"]
       includeEpisodes:NO
         includeImages:YES
         includeActors:YES
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           if ([self showsWithIDsBasicCheckWithID:@"75760"
                                            shows:shows
                                 errorsDictionary:errorsDictionary]) return;
           
           STAssertNil([shows[0] episodes], @"Episodes must be nil");
           STAssertNotNil([shows[0] images], @"Images can't be nil");
           STAssertNotNil([shows[0] actors], @"Actors can't be nil");
       }];
}

- (void)testShowsWithIDsCheckSpecialEpisodes
{
    [LRTVDBAPIClient sharedClient].includeSpecials = YES;
    
    [self showsWithIDs:@[@"121361"]
       includeEpisodes:YES
         includeImages:NO
         includeActors:NO
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           if ([self showsWithIDsBasicCheckWithID:@"121361"
                                            shows:shows
                                 errorsDictionary:errorsDictionary]) return;
           
           STAssertTrue([[shows[0] episodesForSeason:@0] count] > 0, @"We must have episodes with season 0");
       }];
}

- (void)testShowsWithIDsCheckRelationshipsProperties
{
    [self showsWithIDs:@[@"82066"]
       includeEpisodes:YES
         includeImages:YES
         includeActors:YES
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           if ([self showsWithIDsBasicCheckWithID:@"82066"
                                            shows:shows
                                 errorsDictionary:errorsDictionary]) return;
           
           [self checkPropertiesOfEpisodes:[shows[0] episodes]];
           [self checkObjects:[shows[0] episodes] ofClass:[LRTVDBEpisode class]];
           
           [self checkPropertiesOfImages:[shows[0] images]];
           [self checkObjects:[shows[0] images] ofClass:[LRTVDBImage class]];
           
           [self checkPropertiesOfActors:[shows[0] actors]];
           [self checkObjects:[shows[0] actors] ofClass:[LRTVDBActor class]];
           
       }];
}

- (void)testShowsWithIDsCorrectLanguage
{
    [LRTVDBAPIClient sharedClient].language = @"es";
    
    [self showsWithIDs:@[@"75760"]
       includeEpisodes:YES
         includeImages:NO
         includeActors:NO
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           if ([self showsWithIDsBasicCheckWithID:@"75760"
                                            shows:shows
                                 errorsDictionary:errorsDictionary]) return;
           
           STAssertEqualObjects([shows[0] language], @"es", @"Language must be spanish");
           
           for (LRTVDBEpisode *episode in [shows[0] episodes])
           {
               STAssertEqualObjects([episode language], @"es", @"Language must be spanish");
           }
       }];
}

- (void)testShowsWithIDsShowWeakReference
{
    [self showsWithIDs:@[@"75760"]
       includeEpisodes:YES
         includeImages:NO
         includeActors:NO
       completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
           
           if ([self showsWithIDsBasicCheckWithID:@"75760"
                                            shows:shows
                                 errorsDictionary:errorsDictionary]) return;
           
           for (LRTVDBEpisode *episode in [shows[0] episodes])
           {
               STAssertEquals(shows[0], episode.show, @"Episodes's show and show must be the same pointer");
           }
       }];
}

#pragma mark - Episodes with IDs

- (void)testEpisodesWithIDsNullID
{
    [self episodesWithIDs:nil
          completionBlock:^(NSArray *episodes, NSDictionary *errorsDictionary) {
              
              STAssertEqualObjects(episodes, @[], @"Episodes array must be empty");
              STAssertEqualObjects(errorsDictionary, @{}, @"Error dictionary must be empty");
          }];
}

- (void)testEpisodesWithIDsEmptyIDs
{
    [self episodesWithIDs:@[]
          completionBlock:^(NSArray *episodes, NSDictionary *errorsDictionary) {
              
              STAssertEqualObjects(episodes, @[], @"Episodes array must be empty");
              STAssertEqualObjects(errorsDictionary, @{}, @"Error dictionary must be empty");
          }];
}

- (void)testEpisodesWithIDsSameIDsSameOrder
{
    NSArray *episodesIDs = @[@"367882", @"386103", @"386717", @"387578"];
    
    [self episodesWithIDs:episodesIDs
          completionBlock:^(NSArray *episodes, NSDictionary *errorsDictionary) {
              
              [self checkObjects:episodes ofClass:[LRTVDBEpisode class]];
              
              NSMutableArray *mutableEpisodeIDs = [episodesIDs mutableCopy];
              
              [episodesIDs enumerateObjectsUsingBlock:^(NSString *episodeID, NSUInteger idx, BOOL *stop) {
                  
                  if (errorsDictionary[episodeID])
                  {
                      [mutableEpisodeIDs removeObject:episodeID];
                  }
              }];
              
              STAssertTrue([mutableEpisodeIDs count] == [episodes count], @"Must be equal");
              
              [episodes enumerateObjectsUsingBlock:^(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop) {
                  
                  STAssertEqualObjects(episode.episodeID, mutableEpisodeIDs[idx], @"Episodes ids must be the same");
              }];
          }];
}

- (void)testEpisodesWithIDsWrongEpisodeID
{
    NSArray *episodesIDs = @[@"386103", @"jklsdjalfksd"]; // one valid, one not valid
    
    [self episodesWithIDs:episodesIDs
          completionBlock:^(NSArray *episodes, NSDictionary *errorsDictionary) {
              
              [self checkObjects:episodes ofClass:[LRTVDBEpisode class]];
              
              if (errorsDictionary[@"386103"] == nil)
              {
                  STAssertTrue([episodes count] == 1, @"We must have one valid result");
                  STAssertEqualObjects([episodes[0] episodeID], episodesIDs[0], @"Episodes IDs must be the same");
              }
              else
              {
                  STAssertEqualObjects(episodes, @[], @"We must have zero results");
              }
              
              STAssertNotNil(errorsDictionary[episodesIDs[1]], @"Must be an error 404");
          }];
}

- (void)testEpisodesWithIDsFullInformation
{
    [self episodesWithIDs:@[@"387578"]
          completionBlock:^(NSArray *episodes, NSDictionary *errorsDictionary) {
              
              if ([self episodesWithIDsBasicCheckWithID:@"387578"
                                               episodes:episodes
                                       errorsDictionary:errorsDictionary]) return;
              
              [self checkPropertiesOfEpisodes:@[episodes[0]]];
          }];
}

- (void)testEpisodesWithIDsCorrectLanguage
{
    [LRTVDBAPIClient sharedClient].language = @"es";
    
    [self episodesWithIDs:@[@"386103"]
          completionBlock:^(NSArray *episodes, NSDictionary *errorsDictionary) {
              
              if ([self episodesWithIDsBasicCheckWithID:@"386103"
                                               episodes:episodes
                                       errorsDictionary:errorsDictionary]) return;
              
              STAssertEqualObjects([episodes[0] language], @"es", @"Language must be spanish");
          }];
}

#pragma mark - Episode With Season Number and Episode Number

- (void)testEpisodeWithSeasonNumberSameSeasonAndNumber
{
    [self episodeWithSeasonNumber:@2
                    episodeNumber:@5
                    forShowWithID:@"121361"
                  completionBlock:^(LRTVDBEpisode *episode, NSError *error) {
                      
                      if (error)
                      {
                          STAssertNil(episode, @"If error, episode must be nil");
                          return;
                      }
                      
                      STAssertEqualObjects(episode.seasonNumber, @2, @"Season number must be the same");
                      STAssertEqualObjects(episode.episodeNumber, @5, @"Season number must be the same");
                  }];
}

- (void)testEpisodeWithSeasonNumberWrongShowID
{
    [self episodeWithSeasonNumber:@2
                    episodeNumber:@5
                    forShowWithID:@"78943572089435208934879"
                  completionBlock:^(LRTVDBEpisode *episode, NSError *error) {
                      
                      STAssertNotNil(error, @"Must have error 404");
                      STAssertNil(episode, @"Episode must be nil");
                  }];
}

- (void)testEpisodeWithSeasonNumberWrongSeasonNumber
{
    [self episodeWithSeasonNumber:@20
                    episodeNumber:@5
                    forShowWithID:@"121361"
                  completionBlock:^(LRTVDBEpisode *episode, NSError *error) {
                      
                      STAssertNotNil(error, @"Must have error 404");
                      STAssertNil(episode, @"Episode must be nil");
                  }];
}

#pragma mark - Images for Show

- (void)testImagesForShowBasicChecks
{
    [self imagesForShowWithID:@"82066"
              completionBlock:^(NSArray *images, NSError *error) {
                  
                  [self checkObjects:images ofClass:[LRTVDBImage class]];
                  [self checkPropertiesOfImages:images];
              }];
}

- (void)testImagesForShowWrongShowID
{
    [self imagesForShowWithID:@"sdkjlfadlsñklsa"
              completionBlock:^(NSArray *images, NSError *error) {
                  
                  STAssertNotNil(error, @"Must have error 404");
                  STAssertEqualObjects(images, @[], @"Images must be empty");
              }];
}

#pragma mark - Actors for Show

- (void)testActorsForShowBasicChecks
{
    [self actorsForShowWithID:@"82066"
              completionBlock:^(NSArray *actors, NSError *error) {
                  
                  [self checkObjects:actors ofClass:[LRTVDBActor class]];
                  [self checkPropertiesOfActors:actors];
              }];
}

- (void)testActorsForShowWrongShowID
{
    [self actorsForShowWithID:@"sdkjlfadlsñklsa"
              completionBlock:^(NSArray *actors, NSError *error) {
                  
                  STAssertNotNil(error, @"Must have error 404");
                  STAssertEqualObjects(actors, @[], @"Images must be empty");
              }];
}

#pragma mark - Update Shows

- (void)testUpdateShowsBasicChecks
{
    LRTVDBShow *show = [[LRTVDBShow alloc] init];
    [show setValue:@"82066" forKey:@"showID"];
    
    [self updateShows:@[show]
        updateEpisode:YES
         updateImages:YES
         updateActors:YES
      completionBlock:^(BOOL finished) {
          
          [self checkBasicPropertiesOfShow:show];
          [self checkAdvancedPropertiesOfShow:show];
          
          STAssertNotNil(show.episodes, @"We must have valid episodes");
          [self checkObjects:show.episodes ofClass:[LRTVDBEpisode class]];
          [self checkPropertiesOfEpisodes:show.episodes];
          
          STAssertNotNil(show.images, @"We must have valid images");
          [self checkObjects:show.images ofClass:[LRTVDBImage class]];
          [self checkPropertiesOfImages:show.images];
          
          STAssertNotNil(show.actors, @"We must have valid actors");
          [self checkObjects:show.actors ofClass:[LRTVDBActor class]];
          [self checkPropertiesOfActors:show.actors];
      }];
}

- (void)testUpdateShowsLanguage
{
    LRTVDBShow *show = [[LRTVDBShow alloc] init];
    [show setValue:@"82066" forKey:@"showID"];
    [show setValue:[LRTVDBAPIClient sharedClient].language forKey:@"language"];
    
    [LRTVDBAPIClient sharedClient].language = @"es";
    
    [self updateShows:@[show]
        updateEpisode:NO
         updateImages:NO
         updateActors:NO completionBlock:^(BOOL finished) {
             
             STAssertEqualObjects(show.language, @"es", @"Language must be Spanish");
         }];
}

#pragma mark - Update Episodes

- (void)testUpdateEpisodeBasicChecks
{
    LRTVDBEpisode *episode = [[LRTVDBEpisode alloc] init];
    [episode setValue:@"367882" forKey:@"episodeID"];
    
    [self updateEpisodes:@[episode]
         completionBlock:^(BOOL finished) {
             
             [self checkPropertiesOfEpisodes:@[episode]];
         }];
}

#pragma mark - Private

- (void)showsWithname:(NSString *)query completionBlock:(void (^)(NSArray *_shows, NSError *_error))completionBlock
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block NSError *_error = nil;
    __block NSArray *_shows = nil;
    
    [[LRTVDBAPIClient sharedClient] showsWithName:query
                                  completionBlock:^(NSArray *shows, NSError *error) {
                                      
                                      _shows = shows;
                                      _error = error;
                                      
                                      dispatch_semaphore_signal(semaphore);
                                  }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantPast]];
    }
    
    completionBlock(_shows, _error);
}

- (void)showsWithIDs:(NSArray *)showsIDs
     includeEpisodes:(BOOL)includeEpisodes
       includeImages:(BOOL)includeImages
       includeActors:(BOOL)includeActors
     completionBlock:(void (^)(NSArray *shows, NSDictionary *errorsDictionary))completionBlock
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block NSArray *_shows = nil;
    __block NSDictionary *_errorsDictionary = nil;
    
    [[LRTVDBAPIClient sharedClient] showsWithIDs:showsIDs
                                 includeEpisodes:includeEpisodes
                                   includeImages:includeImages
                                   includeActors:includeActors
                                 completionBlock:^(NSArray *shows, NSDictionary *errorsDictionary) {
                                     
                                     _shows = shows;
                                     _errorsDictionary = errorsDictionary;
                                     
                                     dispatch_semaphore_signal(semaphore);
                                 }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantPast]];
    }
    
    completionBlock(_shows, _errorsDictionary);
}

- (void)episodesWithIDs:(NSArray *)episodesIDs
        completionBlock:(void (^)(NSArray *episodes, NSDictionary *errorsDictionary))completionBlock
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block NSArray *_episodes = nil;
    __block NSDictionary *_errorsDictionary = nil;
    
    [[LRTVDBAPIClient sharedClient] episodesWithIDs:episodesIDs
                                    completionBlock:^(NSArray *episodes, NSDictionary *errorsDictionary) {
                                        
                                        _episodes = episodes;
                                        _errorsDictionary = errorsDictionary;
                                        
                                        dispatch_semaphore_signal(semaphore);
                                    }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantPast]];
    }
    
    completionBlock(_episodes, _errorsDictionary);
}

- (void)episodeWithSeasonNumber:(NSNumber *)seasonNumber
                  episodeNumber:(NSNumber *)episodeNumber
                  forShowWithID:(NSString *)showID
                completionBlock:(void (^)(LRTVDBEpisode *episode, NSError *error))completionBlock
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block LRTVDBEpisode *_episode = nil;
    __block NSError *_error = nil;
    
    [[LRTVDBAPIClient sharedClient] episodeWithSeasonNumber:seasonNumber
                                              episodeNumber:episodeNumber
                                              forShowWithID:showID
                                            completionBlock:^(LRTVDBEpisode *episode, NSError *error) {
                                                
                                                _episode = episode;
                                                _error = error;
                                                
                                                dispatch_semaphore_signal(semaphore);
                                            }];    
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantPast]];
    }
    
    completionBlock(_episode, _error);
}

- (void)imagesForShowWithID:(NSString *)showID
            completionBlock:(void (^)(NSArray *images, NSError *error))completionBlock
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block NSArray *_images = nil;
    __block NSError *_error = nil;
    
    [[LRTVDBAPIClient sharedClient] imagesForShowWithID:showID
                                        completionBlock:^(NSArray *images, NSError *error) {
                                            
                                            _images = images;
                                            _error = error;
                                            
                                            dispatch_semaphore_signal(semaphore);
                                        }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantPast]];
    }
    
    completionBlock(_images, _error);
}

- (void)actorsForShowWithID:(NSString *)showID
            completionBlock:(void (^)(NSArray *actors, NSError *error))completionBlock
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block NSArray *_actors = nil;
    __block NSError *_error = nil;
    
    [[LRTVDBAPIClient sharedClient] actorsForShowWithID:showID
                                        completionBlock:^(NSArray *actors, NSError *error) {
                                            
                                            _actors = actors;
                                            _error = error;
                                            
                                            dispatch_semaphore_signal(semaphore);                                            
                                        }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantPast]];
    }
    
    completionBlock(_actors, _error);
}

- (void)updateShows:(NSArray *)showsToUpdate
      updateEpisode:(BOOL)updateEpisodes
       updateImages:(BOOL)updateImages
       updateActors:(BOOL)updateActors
    completionBlock:(void (^) (BOOL finished))completionBlock
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block BOOL _finished = NO;
    
    [[LRTVDBAPIClient sharedClient] updateShows:showsToUpdate
                                  checkIfNeeded:NO
                                 updateEpisodes:updateEpisodes
                                   updateImages:updateImages
                                   updateActors:updateActors
                                completionBlock:^(BOOL finished) {
                                    
                                    _finished = finished;
                                    
                                    dispatch_semaphore_signal(semaphore);
                                }];
        
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantPast]];
    }
    
    completionBlock(_finished);
}

- (void)updateEpisodes:(NSArray *)episodesToUpdate
       completionBlock:(void (^) (BOOL finished))completionBlock
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block BOOL _finished = NO;
    
    [[LRTVDBAPIClient sharedClient] updateEpisodes:episodesToUpdate
                                     checkIfNeeded:NO
                                   completionBlock:^(BOOL finished) {
                                       
                                       _finished = finished;
                                       
                                       dispatch_semaphore_signal(semaphore);
                                   }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantPast]];
    }
    
    completionBlock(_finished);
}

- (void)checkObjects:(NSArray *)objects ofClass:(Class)class
{
    for (id object in objects)
    {
        STAssertTrue([object isKindOfClass:class], @"Wrong class");
    }
}

- (void)checkNilRelationshipsOfShows:(NSArray *)shows
{
    for (LRTVDBShow *show in shows)
    {
        STAssertNil(show.episodes, @"Episodes must be nil");
        STAssertNil(show.images, @"Images must be nil");
        STAssertNil(show.actors, @"Actors must be nil");
    }
}

- (void)checkBasicPropertiesOfShow:(LRTVDBShow *)show
{
    STAssertNotNil(show.showID, @"Show ID can't be nil");
    STAssertNotNil(show.name, @"Name can't be nil");
    STAssertNotNil(show.overview, @"Overview can't be nil");
    STAssertNotNil(show.premiereDate, @"Premiere date can't be nil");
    STAssertNotNil(show.bannerURL, @"Banner URL can't be nil");
    STAssertNotNil(show.language, @"Language can't be nil");
    STAssertNotNil(show.imdbID, @"IMDB ID can't be nil");
}

- (void)checkAdvancedPropertiesOfShow:(LRTVDBShow *)show
{
    STAssertNotNil(show.airDay, @"Air day can't be nil");
    STAssertNotNil(show.airTime, @"Air time can't be nil");
    STAssertNotNil(show.contentRating, @"Content rating can't be nil");
    STAssertNotNil(show.genres, @"Genres can't be nil");
    STAssertNotNil(show.actorsNames, @"Actors names can't be nil");
    STAssertNotNil(show.network, @"Network can't be nil");
    STAssertNotNil(show.runtime, @"Runtime can't be nil");
    STAssertNotNil(show.rating, @"Rating can't be nil");
    STAssertNotNil(show.ratingCount, @"Rating count date can't be nil");
    STAssertNotNil(show.posterURL, @"Poster URL can't be nil");
    STAssertNotNil(show.fanartURL, @"Fanart URL can't be nil");
    STAssertTrue(show.status != LRTVDBShowStatusUnknown, @"Show status can't be unknown");
}

- (BOOL)showsWithNameBasicChecksWithShows:(NSArray *)shows andError:(NSError *)error
{
    if (error)
    {
        STAssertEqualObjects(shows, @[], @"Shows must be empty");
    }
    else
    {
        [self checkObjects:shows ofClass:[LRTVDBShow class]];
        [self checkNilRelationshipsOfShows:shows];
    }
    
    return error != nil;
}

- (BOOL)showsWithIDsBasicCheckWithID:(NSString *)requestedShowID
                               shows:(NSArray *)shows
                    errorsDictionary:(NSDictionary *)errorsDictionary
{
    BOOL error = errorsDictionary[requestedShowID] != nil;
    
    if (error)
    {
        STAssertEqualObjects(shows, @[], @"We must have zero results");
    }
    else
    {
        STAssertTrue([shows count] == 1, @"We must have one result");
        [self checkObjects:shows ofClass:[LRTVDBShow class]];
        STAssertEqualObjects([shows[0] showID], requestedShowID, @"Shows IDs must be the same");
    }
    
    return error;
}

- (BOOL)episodesWithIDsBasicCheckWithID:(NSString *)requestedEpisodeID
                               episodes:(NSArray *)episodes
                       errorsDictionary:(NSDictionary *)errorsDictionary
{
    BOOL error = errorsDictionary[requestedEpisodeID] != nil;
    
    if (error)
    {
        STAssertEqualObjects(episodes, @[], @"We must have zero results");
    }
    else
    {
        STAssertTrue([episodes count] == 1, @"We must have one result");
        [self checkObjects:episodes ofClass:[LRTVDBEpisode class]];
        STAssertEqualObjects([episodes[0] episodeID], requestedEpisodeID, @"Episode IDs must be the same");
    }
    
    return error;
}

- (void)checkPropertiesOfEpisodes:(NSArray *)episodes
{
    for (LRTVDBEpisode *episode in episodes)
    {
        // The other properties may be nil.
        STAssertNotNil(episode.episodeID, @"Episode ID can't be nil");
        STAssertNotNil(episode.title, @"Title can't be nil");
        STAssertNotNil(episode.episodeNumber, @"Episode number can't be nil");
        STAssertNotNil(episode.seasonNumber, @"Season ID can't be nil");
        STAssertNotNil(episode.rating, @"Rating can't be nil");
        STAssertNotNil(episode.airedDate, @"Aired Date can't be nil");
        STAssertNotNil(episode.overview, @"Overview can't be nil");
        STAssertNotNil(episode.imageURL, @"Image URL can't be nil");
        STAssertNotNil(episode.language, @"Language can't be nil");
        STAssertNotNil(episode.showID, @"Show ID can't be nil");
    }
}

- (void)checkPropertiesOfImages:(NSArray *)images
{
    for (LRTVDBImage *image in images)
    {
        // The other properties may be nil.
        STAssertNotNil(image.url, @"Image URL can't be nil");
        STAssertTrue(image.type != LRTVDBImageTypeUnknown, @"Image type must be known.");
    }
}

- (void)checkPropertiesOfActors:(NSArray *)actors
{
    for (LRTVDBActor *actor in actors)
    {
        STAssertNotNil(actor.actorID, @"Actor ID can't be nil");
        STAssertNotNil(actor.name, @"Name can't be nil");
        STAssertNotNil(actor.role, @"Role can't be nil");
        STAssertNotNil(actor.imageURL, @"Image URL can't be nil");
        STAssertNotNil(actor.sortOrder, @"Sort Order can't be nil");
    }
}

@end
