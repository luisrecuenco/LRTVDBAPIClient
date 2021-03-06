// LRTVDBAPIClient.h
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

#import "AFHTTPClient.h"

@class LRTVDBShow;
@class LRTVDBEpisode;

/**
 Objective - C wrapper around theTVDB API.
 @see http://thetvdb.com/wiki/index.php/Programmers_API
 */
@interface LRTVDBAPIClient : AFHTTPClient

/**
 The API key used to communicate with TVDB API.
 @remarks If not set, the default TVDB API key will be used.
 */
@property (nonatomic, copy) NSString *apiKey;

/**
 The default language to be used in the API calls.
 @discussion The supported TVDB languages  can be seen in LRTVDBLanguages() method
 or in the URL shown below. If no language provided (or the language provided is
 not available for theTVDB API), the device default language will be used. If
 the latter is not available for theTVDB API either, the default TVDB language
 (English) will be used.
 @see http://www.thetvdb.com/api/74204F775D9D3C87/languages.xml
 */
@property (nonatomic, copy) NSString *language;

/**
 Use this property to include special episodes, i.e., episodes with season 0.
 */
@property (nonatomic) BOOL includeSpecials;

/**
 Use this property to force the show metadata to be in English.
 */
@property (nonatomic) BOOL forceEnglishMetadata;

/**
 Shared API client object.
 @return The singleton API client instance.
 */
+ (LRTVDBAPIClient *)sharedClient;

/**
 Retrieves a list of LRTVDBShow objects.
 @param showName The name of the show.
 @param completionBlock A block object to be executed upon the completion of the
 request containing an array of LRTVDBShow instances and the error if any problem occures.
 @discussion This method retrieves LRTVDBShow objects with basic information, i.e., only the following properties in LRTVDBShow will be available:
 
 - showID
 - name
 - overview
 - premiereDate
 - imdbID
 - language
 - bannerURL
 
 In order to retrieve more information about the show,
 showsWithIDs:includeEpisodes:includeImages:includeActors:completionBlock:
 or updateShows:updateEpisodes:updateImages:updateActors:completionBlock:
 methods can be used.
 */
- (void)showsWithName:(NSString *)showName
      completionBlock:(void (^)(NSArray *shows, NSError *error))completionBlock;

/**
 Retrieves full information about the provided shows.
 @param showsIDs Array with the ids of the shows.
 @param includeEpisodes Flag used to retrieve the show episodes.
 @param includeImages Flag used to retrieve the show images.
 @param includeActors Flag used to retrieve the show actors.
 @param completionBlock A block object to be executed upon the completion of the request
 containing an array of sorted LRTVDBShow instances (the same order as the ones in
 the showsIDs array) and a dictionary of errors in case of any problems when retrieving
 any show (@{showID : NSError}).
 */
- (void)showsWithIDs:(NSArray *)showsIDs
     includeEpisodes:(BOOL)includeEpisodes
       includeImages:(BOOL)includeImages
       includeActors:(BOOL)includeActors
     completionBlock:(void (^)(NSArray *shows, NSDictionary *errorsDictionary))completionBlock;

/**
 Retrieves full information about the provided episodes.
 @param episodesIDs Array with the ids of the episodes.
 @param completionBlock A block object to be executed upon the completion of the request
 containing an array of sorted LRTVDBEpisode instances (the same order as the ones in
 the episodesIDs array) and a dictionary of errors in case of any problems when retrieving
 any episode (@{episodeID : NSError}).
 */
- (void)episodesWithIDs:(NSArray *)episodesIDs
        completionBlock:(void (^)(NSArray *episodes, NSDictionary *errorsDictionary))completionBlock;

/**
 Retrieves episode information.
 @param seasonNumber Season of the episode.
 @param episodeNumber Number of the episode.
 @param showID ID of the show.
 @param completionBlock A block object to be executed upon the completion of the request
 containing a LRTVDBEpisode instance and an error if any problem arises.
 */
- (void)episodeWithSeasonNumber:(NSNumber *)seasonNumber
                  episodeNumber:(NSNumber *)episodeNumber
                  forShowWithID:(NSString *)showID
                completionBlock:(void (^)(LRTVDBEpisode *episode, NSError *error))completionBlock;

/**
 Retrieves images information about the provided show.
 @param showID ID of the show.
 @param completionBlock A block object to be executed upon the completion of the request
 containing an array of sorted LRTVDBImage instances and an error if any problem arises.
 */
- (void)imagesForShowWithID:(NSString *)showID
            completionBlock:(void (^)(NSArray *images, NSError *error))completionBlock;

/**
 Retrieves actors information about the provided show.
 @param showID ID of the show.
 @param completionBlock A block object to be executed upon the completion of the request
 containing an array of sorted LRTVDBActor instances and an error if any problem arises.
 */
- (void)actorsForShowWithID:(NSString *)showID
            completionBlock:(void (^)(NSArray *actors, NSError *error))completionBlock;

/**
 Updates a list of shows.
 @param showsToUpdate Array of LRTVDBShow instances to be updated.
 @param checkIfNeeded if YES, checks if the show needs to be updated
 since the last update (changed by refreshLastUpdateTimestamp).
 @param updateEpisodes Flag used to update the show episodes.
 @param updateImages Flag used to update the show images.
 @param updateActors Flag used to update the show actors.
 @param replaceArtwork Flag used to replace bannerURL, fanartURL and posterURL.
 @param completionBlock A block object to be executed upon the completion of the request
 containing a BOOL indicating the operation success (every show update went ok) or failure
 (there was an error in any of the shows).
 */
- (void)updateShows:(NSArray *)showsToUpdate
      checkIfNeeded:(BOOL)checkIfNeeded
     updateEpisodes:(BOOL)updateEpisodes
       updateImages:(BOOL)updateImages
       updateActors:(BOOL)updateActors
     replaceArtwork:(BOOL)replaceArtwork
    completionBlock:(void (^)(BOOL finished))completionBlock;

/**
 Updates a list of episodes.
 @param episodesToUpdate Array of LRTVDBEpisode instances to be updated.
 @param checkIfNeeded if YES, checks if the episode needs to be updated
 since the last update (changed by refreshLastUpdateTimestamp).
 @param completionBlock A block object to be executed upon the completion of the request
 containing a BOOL indicating the operation success (every episode update went ok) or failure
 (there was an error in any of the episodes).
 */
- (void)updateEpisodes:(NSArray *)episodesToUpdate
         checkIfNeeded:(BOOL)checkIfNeeded
       completionBlock:(void (^)(BOOL finished))completionBlock;

/**
 Retrieves the list of shows ids to be updated since the last update.
 @param completionBlock A block object to be executed upon the completion of the request
 containing an array of shows ids (NSString's) and an error if any problem arises.
 */
- (void)showsIDsToUpdateWithCompletionBlock:(void (^)(NSArray *showsIDs, NSError *error))completionBlock;

/**
 Retrieves the list of episodes ids to be updated since the last update.
 @param completionBlock A block object to be executed upon the completion of the request
 containing an array of episodes ids (NSString's) and an error if any problem arises.
 */
- (void)episodesIDsToUpdateWithCompletionBlock:(void (^)(NSArray *episodesIDs, NSError *error))completionBlock;

/**
 Refreshes the last update timestamp.
 @remarks A normal use case for this method would be using it after
 updateShows:checkIfNeeded:updateEpisodes:updateImages:updateActors:completionBlock:.
 */
- (void)refreshLastUpdateTimestamp;

/**
 Cancels an ongoing showsWithName request.
 @param showName The name of the show whose request is wanted to be cancelled.
 */
- (void)cancelShowsWithNameRequest:(NSString *)showName;

/**
 Cancels ongoing showWithID requests.
 @param showsIDs Array with the ids of the shows whose requests are wanted to be cancelled.
 @param includeEpisodes, includeImages, includeActors Flags to build the correct request URL to cancel.
 */
- (void)cancelShowsWithIDsRequests:(NSArray *)showsIDs
                   includeEpisodes:(BOOL)includeEpisodes
                     includeImages:(BOOL)includeImages
                     includeActors:(BOOL)includeActors;

/**
 Cancels ongoing updateShow requests.
 @param showsToCancel Array of LRTVDBShow instances whose update requests are wanted to be cancelled.
 @param updateEpisodes, updateImages, updateActors Flags to build the correct request URL to cancel.
 */
- (void)cancelUpdateOfShowsRequests:(NSArray *)showsToCancel
                     updateEpisodes:(BOOL)updateEpisodes
                       updateImages:(BOOL)updateImages
                       updateActors:(BOOL)updateActors;

/**
 Cancels every ongoing TVDB API Client request.
 */
- (void)cancelAllTVDBAPIClientRequests;

/**
 @return theTVDB show URL (http://thetvdb.com/?tab=series&id=seriesID&lid=languageID).
 */
NSURL *LRTVDBURLForShow(LRTVDBShow *show);

@end
