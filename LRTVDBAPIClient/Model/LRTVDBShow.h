// LRTVDBShow.h
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

#import "LRTVDBSerializableModelProtocol.h"

/**
 Show comparison block.
 */
extern NSComparator LRTVDBShowComparator;

/**
 Struct in order to make KVO a little more strong typed.
 
 @discussion When observing a key value like @"episodes", use
 LRTVDBShowAttributes.episodes instead."
 */
extern const struct LRTVDBShowAttributes
{
    __unsafe_unretained NSString *activeEpisode;
    __unsafe_unretained NSString *fanartURL;
    __unsafe_unretained NSString *posterURL;
    __unsafe_unretained NSString *lastEpisode;
    __unsafe_unretained NSString *episodes;
    __unsafe_unretained NSString *images;
    __unsafe_unretained NSString *actors;
} LRTVDBShowAttributes;

typedef NS_ENUM(NSInteger, LRTVDBShowStatus)
{
    LRTVDBShowStatusUnknown,
    LRTVDBShowStatusUpcoming, /** Next episode air date is well known. */
    LRTVDBShowStatusTBA, /** To be Announced, i.e., next episode air date is unknown. */
    LRTVDBShowStatusEnded, /** Show no longer airs. */
};

@class LRTVDBEpisode;

@interface LRTVDBShow : NSObject <LRTVDBSerializableModelProtocol>

/**
 Basic properties, i.e., the ones obtained when retrieving
 http://www.thetvdb.com/api/GetSeries.php?seriesname=seriesName&language=all
 */

@property (nonatomic, copy, readonly) NSString *showID;
@property (nonatomic, copy, readonly) NSString *name;

/** Brief general description. */
@property (nonatomic, copy, readonly) NSString *overview;

/** Date in which the show was first aired. */
@property (nonatomic, strong, readonly) NSDate *premiereDate;

@property (nonatomic, copy, readonly) NSString *imdbID;

/** Example: http://www.imdb.com/title/tt1119644/ */
@property (nonatomic, readonly) NSURL *imdbURL;

@property (nonatomic, copy, readonly) NSString *language;

/**
 Example: http://www.thetvdb.com/banners/graphical/82066-g38.jpg
 @see LRTVDBImage for more info.
 */
@property (nonatomic, strong) NSURL *bannerURL;


/**
 Not so basic properties, i.e., the ones obtained when retrieving
 http://www.thetvdb.com/api/API_KEY/series/SHOW_ID/all/language(.zip)
 */

@property (nonatomic, copy, readonly) NSString *airDay; /** Monday, Tuesday... */
@property (nonatomic, copy, readonly) NSString *airTime; /** 9:00 PM */
@property (nonatomic, copy, readonly) NSString *contentRating; /** TV-14 */
@property (nonatomic, copy, readonly) NSArray *genres;

/** Array of actors names.
 @discussion This property only contains the actors names (NSString *).
 For the more useful array with LRTVDBActor instances, see
 actors property below.
 */
@property (nonatomic, copy, readonly) NSArray *actorsNames;

@property (nonatomic, copy, readonly) NSString *network; /** ABC, HBO... */
@property (nonatomic, strong, readonly) NSNumber *runtime;
@property (nonatomic, strong, readonly) NSNumber *rating;
@property (nonatomic, strong, readonly) NSNumber *ratingCount;

/**
 Example: http://www.thetvdb.com/banners/posters/82066-53.jpg
 @see LRTVDBImage for more info.
 */
@property (nonatomic, strong) NSURL *posterURL;

/**
 Example: http://www.thetvdb.com/banners/fanart/original/82066-78.jpg
 @see LRTVDBImage for more info.
 */
@property (nonatomic, strong) NSURL *fanartURL;

@property (nonatomic, readonly) LRTVDBShowStatus status;


/** Relationships */

@property (nonatomic, copy, readonly) NSArray *episodes;

@property (nonatomic, strong, readonly) LRTVDBEpisode *lastEpisode;
@property (nonatomic, strong, readonly) LRTVDBEpisode *nextEpisode;
@property (nonatomic, strong, readonly) NSNumber *daysToNextEpisode;
@property (nonatomic, strong, readonly) NSNumber *numberOfSeasons;

/**
 Number of pending episodes to finish the show
 */
@property (nonatomic, assign, readonly) NSUInteger numberOfEpisodesBehind;

/**
 The next episode to be watched, i.e., the active one
 */
@property (nonatomic, strong, readonly) LRTVDBEpisode *activeEpisode;

/**
 Active means that at least one episode of the show has been watched
 */
@property (nonatomic, readonly, getter = isActive) BOOL active;

/**
 Has the first episode already aired?
 */
@property (nonatomic, readonly, getter = hasStarted) BOOL started;

@property (nonatomic, readonly, getter = hasBeenFinished) BOOL finished;

/** Ordered set of LRTVDBImage objects. */
@property (nonatomic, copy, readonly) NSArray *images;

/**
 @see LRTVDBImage class to see an example of the different image types.
 */
@property (nonatomic, copy, readonly) NSArray *fanartImages;
@property (nonatomic, copy, readonly) NSArray *posterImages;
@property (nonatomic, copy, readonly) NSArray *seasonImages;
@property (nonatomic, copy, readonly) NSArray *bannerImages;

/** Array of LRTVDBActor instances. */
@property (nonatomic, copy, readonly) NSArray *actors;

/**
 Retrieves the episodes for a specific show season.
 @param seasonNumber The season you want to retrieve the episodes for.
 @return A NSArray object of LRTVDBEpisode instances.
 */
- (NSArray *)episodesForSeason:(NSNumber *)seasonNumber;

/**
 Refreshes episodes information about a show.
 
 @discussion lastEpisode, nextEpisode and daysToNextEpisode depend on the
 current date ([NSDate date]). One valid option could be computing this values
 in the corresponding lazy getters without caching anything. Thus,
 [NSDate date] would be different and so would be last and
 next episode. As this values are very common to be shown in tableViews,
 it's not a good idea to compute them every time while the user is scrolling due
 to performance-wise reasons (even if this time is not that big).
 So, if this values need to be updated/refreshed, this method clears the cache
 and updates them based on the new [NSDate date] value.
 */
- (void)refreshEpisodesInfomation;

@end
