// LRTVDBEpisode.m
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

#import "LRTVDBEpisode.h"
#import "LRTVDBAPIClient.h"
#import "NSString+LRTVDBAdditions.h"

@interface LRTVDBEpisode ()

@property (nonatomic, copy) NSString *episodeID;
@property (nonatomic, copy) NSString *imdbID;
@property (nonatomic, copy) NSString *language;
@property (nonatomic, copy) NSString *showID;
@property (nonatomic, copy) NSString *writers;
@property (nonatomic, copy) NSString *directors;
@property (nonatomic, copy) NSString *guestStars;

@property (nonatomic, strong) NSNumber *episodeNumber;
@property (nonatomic, strong) NSNumber *seasonNumber;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSNumber *ratingCount;
@property (nonatomic, strong) NSURL *artworkURL;
@property (nonatomic, strong) NSDate *airedDate;

@property (nonatomic, copy) NSString *episodeNumberString;
@property (nonatomic, copy) NSString *seasonNumberString;
@property (nonatomic, copy) NSString *ratingString;
@property (nonatomic, copy) NSString *ratingCountString;
@property (nonatomic, copy) NSString *airedDateString;
@property (nonatomic, copy) NSString *artworkURLString;

@end

@implementation LRTVDBEpisode

#pragma mark - Custom Setters

- (void)setTitle:(NSString *)title
{
    _title = [title unescapeHTMLEntities];
}

- (void)setOverview:(NSString *)overview
{
    _overview = [overview unescapeHTMLEntities];
}

- (void)setSeasonNumberString:(NSString *)seasonNumberString
{
    _seasonNumberString = seasonNumberString;
    self.seasonNumber = @(_seasonNumberString.integerValue);
}

- (void)setEpisodeNumberString:(NSString *)episodeNumberString
{
    _episodeNumberString = episodeNumberString;
    self.episodeNumber = @(_episodeNumberString.integerValue);
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

- (void)setAiredDateString:(NSString *)airedDateString
{
    _airedDateString = airedDateString;
    self.airedDate = _airedDateString.dateValue;
}

- (void)setArtworkURLString:(NSString *)artworkURLString
{
    _artworkURLString = artworkURLString;
    self.artworkURL = LRTVDBArtworkURLForPath(_artworkURLString);
}

#pragma mark - Update episode

- (void)updateWithEpisode:(LRTVDBEpisode *)updatedEpisode;
{
    NSAssert([self isEqual:updatedEpisode], @"Trying to update episode with one with different ID?");
    
    self.episodeID = updatedEpisode.episodeID;
    self.title = updatedEpisode.title;
    self.episodeNumberString = updatedEpisode.episodeNumberString;
    self.seasonNumberString = updatedEpisode.seasonNumberString;
    self.ratingString = updatedEpisode.ratingString;
    self.ratingCountString = updatedEpisode.ratingCountString;
    self.airedDateString = updatedEpisode.airedDateString;
    self.overview = updatedEpisode.overview;
    self.artworkURLString = updatedEpisode.artworkURLString;
    self.imdbID = updatedEpisode.imdbID;
    self.language = updatedEpisode.language;
    self.showID = updatedEpisode.showID;
    self.writers = updatedEpisode.writers;
    self.directors = updatedEpisode.directors;
    self.guestStars = updatedEpisode.guestStars;
}

#pragma mark - LRKVCBaseModelProtocol

- (NSDictionary *)mappings
{
    return @{ @"id" : @"episodeID",
              @"EpisodeName" : @"title",
              @"EpisodeNumber": @"episodeNumberString",
              @"SeasonNumber": @"seasonNumberString",
              @"Rating": @"ratingString",
              @"RatingCount" : @"ratingCountString",
              @"FirstAired" : @"airedDateString",
              @"Overview" : @"overview",
              @"filename" : @"artworkURLString",
              @"IMDB_ID" : @"imdbID",
              @"Language" : @"language",
              @"seriesid" : @"showID",
              @"Writer" : @"writers",
              @"Director" : @"directors",
              @"GuestStars" : @"guestStars"
            };
}

#pragma mark - Equality methods

- (BOOL)isEqual:(id)object
{
    return [self.episodeID isEqualToString:[(LRTVDBEpisode *)object episodeID]];
}

- (NSUInteger)hash
{
    return [self.episodeID hash];
}

#pragma mark - Description

- (NSString *)description
{
	return [NSString stringWithFormat:@"Title: %@\nSeason number: %@\nEpisode number: %@\nRating: %@\nOverview: %@\n", self.title, self.seasonNumber, self.episodeNumber, self.rating, self.overview];
}

@end
