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

#import "LRKVCBaseModel.h"

typedef NS_ENUM(NSInteger, LRTVDBShowStatus)
{
    LRTVDBShowStatusUnknown,
    LRTVDBShowStatusUpcoming, /** Next episode air date is well known. */
    LRTVDBShowStatusTBA, /** To be Announced, i.e., next episode air date is unknown. */
    LRTVDBShowStatusEnded, /** Show no longer airs. */
};

@class LRTVDBEpisode;

@interface LRTVDBShow : LRKVCBaseModel

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

/** Example: http://www.imdb.com/title/imdbID (http://www.imdb.com/title/tt1119644/) */
@property (nonatomic, copy, readonly) NSString *imdbID;

@property (nonatomic, copy, readonly) NSString *language;

/**
 Example: http:/www.thetvdb.com/banners/graphical/82066-g38.jpg
 @see LRTVDBArtwork for more info.
 */
@property (nonatomic, strong, readonly) NSURL *bannerURL;


/**
 Not so basic properties, i.e., the ones obtained when retrieving
 http://www.thetvdb.com/api/API_KEY/series/SHOW_ID/all/language(.zip)
 */

@property (nonatomic, copy, readonly) NSString *airDay; /** Monday, Tuesday... */
@property (nonatomic, copy, readonly) NSString *airTime; /** 9:00 PM */
@property (nonatomic, copy, readonly) NSString *contentRating; /** TV-14 */
@property (nonatomic, copy, readonly) NSString *genres; /** |Genre 1|Genre 2|... */
@property (nonatomic, copy, readonly) NSString *actorsNames; /** |Actor 1|Actor 2|... */
@property (nonatomic, copy, readonly) NSString *network; /** ABC, HBO... */
@property (nonatomic, strong, readonly) NSNumber *rating;
@property (nonatomic, strong, readonly) NSNumber *ratingCount;
@property (nonatomic, copy, readonly) NSString *runtime;

/**
 Example: http:/www.thetvdb.com/banners/posters/82066-53.jpg
 @see LRTVDBArtwork for more info.
 */
@property (nonatomic, strong, readonly) NSURL *posterURL;

/**
 Example: http:/www.thetvdb.com/banners/fanart/original/82066-78.jpg
 @see LRTVDBArtwork for more info.
 */
@property (nonatomic, strong, readonly) NSURL *fanartURL;

@property (nonatomic, readonly) LRTVDBShowStatus showStatus;


/** Relationships */

/** Ordered set of LRTVDBEpisode objects. */
@property (nonatomic, copy, readonly) NSOrderedSet *episodes;

@property (nonatomic, strong, readonly) LRTVDBEpisode *lastEpisode;
@property (nonatomic, strong, readonly) LRTVDBEpisode *nextEpisode;
@property (nonatomic, strong, readonly) NSNumber *daysToNextEpisode;
@property (nonatomic, strong, readonly) NSNumber *numberOfSeasons;

/** Ordered set of LRTVDBArtwork objects. */
@property (nonatomic, copy, readonly) NSOrderedSet *artworks;

/**
 @see LRTVDBArtwork class to see an example of the different artwork types.
 */
@property (nonatomic, copy, readonly) NSOrderedSet *fanartArtworks;
@property (nonatomic, copy, readonly) NSOrderedSet *posterArtworks;
@property (nonatomic, copy, readonly) NSOrderedSet *seasonArtworks;
@property (nonatomic, copy, readonly) NSOrderedSet *bannerArtworks;

/** Ordered set of LRTVDBActor instances. */
@property (nonatomic, copy, readonly) NSOrderedSet *actors;

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
