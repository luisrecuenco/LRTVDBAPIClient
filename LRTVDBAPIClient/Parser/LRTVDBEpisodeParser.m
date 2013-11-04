// LRTVDBEpisodeParser.m
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

#import "LRTVDBAPIClient+Private.h"
#import "LRTVDBAPIClient.h"
#import "LRTVDBEpisode+Private.h"
#import "LRTVDBEpisodeParser.h"
#import "NSString+LRTVDBAdditions.h"
#import "TBXML.h"

// XML keys
static NSString *const kLRTVDBEpisodeSiblingXMLKey = @"Episode";
static NSString *const kLRTVDBEpisodeIdXMLKey = @"id";
static NSString *const kLRTVDBEpisodeTitleXMLKey = @"EpisodeName";
static NSString *const kLRTVDBEpisodeOverviewXMLKey = @"Overview";
static NSString *const kLRTVDBEpisodeLanguageXMLKey = @"Language";
static NSString *const kLRTVDBEpisodeArtworkURLXMLKey = @"filename";
static NSString *const kLRTVDBEpisodeImdbXMLKey = @"IMDB_ID";
static NSString *const kLRTVDBEpisodeShowIdXMLKey = @"seriesid";
static NSString *const kLRTVDBEpisodeDirectorsXMLKey = @"Director";
static NSString *const kLRTVDBEpisodeWritersXMLKey = @"Writer";
static NSString *const kLRTVDBEpisodeGuestStarsXMLKey = @"GuestStars";
static NSString *const kLRTVDBEpisodeAiredDateXMLKey = @"FirstAired";
static NSString *const kLRTVDBEpisodeRatingXMLKey = @"Rating";
static NSString *const kLRTVDBEpisodeRatingCountXMLKey = @"RatingCount";
static NSString *const kLRTVDBEpisodeNumberXMLKey = @"EpisodeNumber";
static NSString *const kLRTVDBEpisodeSeasonNumberXMLKey = @"SeasonNumber";

@implementation LRTVDBEpisodeParser

+ (instancetype)parser
{
    return [[self alloc] init];
}

- (NSArray *)episodesFromData:(NSData *)data
{
    NSError *error = nil;
    TBXML *tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
    TBXMLElement *root = tbxml.rootXMLElement;
    
    if (error || !root) return nil;
    
    TBXMLElement *episodeElement = [TBXML childElementNamed:kLRTVDBEpisodeSiblingXMLKey parentElement:root];
    
    NSMutableArray *episodes = [NSMutableArray array];
    
    while (episodeElement != nil)
    {
        LRTVDBEpisode *episode = [[LRTVDBEpisode alloc] init];
        
        TBXMLElement *episodeIdElement = [TBXML childElementNamed:kLRTVDBEpisodeIdXMLKey parentElement:episodeElement];
        TBXMLElement *episodeTitleElement = [TBXML childElementNamed:kLRTVDBEpisodeTitleXMLKey parentElement:episodeElement];
        TBXMLElement *episodeOverviewElement = [TBXML childElementNamed:kLRTVDBEpisodeOverviewXMLKey parentElement:episodeElement];
        TBXMLElement *episodeLanguageElement = [TBXML childElementNamed:kLRTVDBEpisodeLanguageXMLKey parentElement:episodeElement];
        TBXMLElement *episodeImageUrlElement = [TBXML childElementNamed:kLRTVDBEpisodeArtworkURLXMLKey parentElement:episodeElement];
        TBXMLElement *episodeImdbIdElement = [TBXML childElementNamed:kLRTVDBEpisodeImdbXMLKey parentElement:episodeElement];
        TBXMLElement *episodeShowIdElement = [TBXML childElementNamed:kLRTVDBEpisodeShowIdXMLKey parentElement:episodeElement];
        TBXMLElement *episodeDirectorsElement = [TBXML childElementNamed:kLRTVDBEpisodeDirectorsXMLKey parentElement:episodeElement];
        TBXMLElement *episodeWritersElement = [TBXML childElementNamed:kLRTVDBEpisodeWritersXMLKey parentElement:episodeElement];
        TBXMLElement *episodeGuestStarsElement = [TBXML childElementNamed:kLRTVDBEpisodeGuestStarsXMLKey parentElement:episodeElement];
        TBXMLElement *episodeAiredDateElement = [TBXML childElementNamed:kLRTVDBEpisodeAiredDateXMLKey parentElement:episodeElement];
        TBXMLElement *episodeRatingElement = [TBXML childElementNamed:kLRTVDBEpisodeRatingXMLKey parentElement:episodeElement];
        TBXMLElement *episodeRatingCountElement = [TBXML childElementNamed:kLRTVDBEpisodeRatingCountXMLKey parentElement:episodeElement];
        TBXMLElement *episodeSeasonNumberElement = [TBXML childElementNamed:kLRTVDBEpisodeSeasonNumberXMLKey parentElement:episodeElement];
        TBXMLElement *episodeNumberElement = [TBXML childElementNamed:kLRTVDBEpisodeNumberXMLKey parentElement:episodeElement];

        if (episodeIdElement) episode.episodeID = LREmptyStringToNil([TBXML textForElement:episodeIdElement]);
        if (episodeTitleElement) episode.title = [LREmptyStringToNil([TBXML textForElement:episodeTitleElement]) unescapeHTMLEntities];
        if (episodeOverviewElement) episode.overview = [LREmptyStringToNil([TBXML textForElement:episodeOverviewElement]) unescapeHTMLEntities];
        if (episodeLanguageElement) episode.language = LREmptyStringToNil([TBXML textForElement:episodeLanguageElement]);
        if (episodeImageUrlElement) episode.imageURL = LRTVDBImageURLForPath(LREmptyStringToNil([TBXML textForElement:episodeImageUrlElement]));
        if (episodeImdbIdElement) episode.imdbID = LREmptyStringToNil([TBXML textForElement:episodeImdbIdElement]);
        if (episodeShowIdElement) episode.showID = LREmptyStringToNil([TBXML textForElement:episodeShowIdElement]);
        if (episodeDirectorsElement) episode.directors = [[LREmptyStringToNil([TBXML textForElement:episodeDirectorsElement]) pipedStringToArray] arrayByRemovingDuplicates];
        if (episodeWritersElement) episode.writers = [[LREmptyStringToNil([TBXML textForElement:episodeWritersElement]) pipedStringToArray] arrayByRemovingDuplicates];
        if (episodeGuestStarsElement) episode.guestStars = [[LREmptyStringToNil([TBXML textForElement:episodeGuestStarsElement]) pipedStringToArray] arrayByRemovingDuplicates];
        if (episodeAiredDateElement) episode.airedDate = [LREmptyStringToNil([TBXML textForElement:episodeAiredDateElement]) dateValue];
        if (episodeRatingElement) episode.rating = @([LREmptyStringToNil([TBXML textForElement:episodeRatingElement]) floatValue]);
        if (episodeRatingCountElement) episode.ratingCount = @([LREmptyStringToNil([TBXML textForElement:episodeRatingCountElement]) integerValue]);
        if (episodeSeasonNumberElement) episode.seasonNumber = @([LREmptyStringToNil([TBXML textForElement:episodeSeasonNumberElement]) integerValue]);
        if (episodeNumberElement) episode.episodeNumber = @([LREmptyStringToNil([TBXML textForElement:episodeNumberElement]) integerValue]);

        BOOL shouldIncludeEpisode = YES;
        
        if ([LRTVDBAPIClient sharedClient].includeSpecials == NO)
        {
            shouldIncludeEpisode = ![episode isSpecial];
        }
        
        if (shouldIncludeEpisode && [episode isCorrect])
        {
            [episodes addObject:episode];
        }
        
        episodeElement = [TBXML nextSiblingNamed:kLRTVDBEpisodeSiblingXMLKey searchFromElement:episodeElement];
    }
    
    return [episodes copy];    
}

- (NSArray *)episodesIDsFromData:(NSData *)data
{
    NSMutableArray *mutableEpisodesIDs = [NSMutableArray array];
    
    NSError *error = nil;
    TBXML *tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
    
    TBXMLElement *root = tbxml.rootXMLElement;
    
    if (root && !error)
    {
        TBXMLElement *episodes = [TBXML childElementNamed:kLRTVDBEpisodeSiblingXMLKey parentElement:root];
        
        while (episodes != nil)
        {
            [mutableEpisodesIDs addObject:[TBXML textForElement:episodes]];
            episodes = [TBXML nextSiblingNamed:kLRTVDBEpisodeSiblingXMLKey searchFromElement:episodes];
        }
    }
    
    return [mutableEpisodesIDs copy];
}

@end
