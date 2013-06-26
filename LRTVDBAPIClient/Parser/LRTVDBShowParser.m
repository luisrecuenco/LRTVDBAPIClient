// LRTVDBShowParser.m
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
#import "LRTVDBShow+Private.h"
#import "LRTVDBShowParser.h"
#import "NSString+LRTVDBAdditions.h"
#import "TBXML.h"

// XML keys
static NSString *const kLRTVDBShowSiblingXMLKey = @"Series";
static NSString *const kLRTVDBShowIdXMLKey = @"id";
static NSString *const kLRTVDBShowNameXMLKey = @"SeriesName";
static NSString *const kLRTVDBShowOverviewXMLKey = @"Overview";
static NSString *const kLRTVDBShowLanguageXMLKey = @"Language";
static NSString *const kLRTVDBShowBannerXMLKey = @"banner";
static NSString *const kLRTVDBShowPosterXMLKey = @"poster";
static NSString *const kLRTVDBShowFanartXMLKey = @"fanart";
static NSString *const kLRTVDBShowAirTimeXMLKey = @"Airs_Time";
static NSString *const kLRTVDBShowAirDayXMLKey = @"Airs_DayOfWeek";
static NSString *const kLRTVDBShowPremiereDateXMLKey = @"FirstAired";
static NSString *const kLRTVDBShowGenresXMLKey = @"Genre";
static NSString *const kLRTVDBShowActorsXMLKey = @"Actors";
static NSString *const kLRTVDBShowImdbXMLKey = @"IMDB_ID";
static NSString *const kLRTVDBShowNetworkXMLKey = @"Network";
static NSString *const kLRTVDBShowRatingXMLKey = @"Rating";
static NSString *const kLRTVDBShowRatingCountXMLKey = @"RatingCount";
static NSString *const kLRTVDBShowContentRatingXMLKey = @"ContentRating";
static NSString *const kLRTVDBShowRuntimeXMLKey = @"Runtime";
static NSString *const kLRTVDBShowBasicStatusXMLKey = @"Status";
static NSString *const kLRTVDBShowBasicStatusContinuingXMLKey = @"Continuing";
static NSString *const kLRTVDBShowBasicStatusEndedXMLKey = @"Ended";

@implementation LRTVDBShowParser

+ (instancetype)parser
{
    return [[self alloc] init];
}

- (NSArray *)showsFromData:(NSData *)data
{
    NSError *error = nil;
    TBXML *tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
    TBXMLElement *root = tbxml.rootXMLElement;
        
    if (error || !root) return nil;
    
    TBXMLElement *showElement = [TBXML childElementNamed:kLRTVDBShowSiblingXMLKey parentElement:root];
    
    NSMutableArray *shows = [NSMutableArray array];
    
    while (showElement != nil)
    {
        LRTVDBShow *show = [[LRTVDBShow alloc] init];
        
        TBXMLElement *showIdElement = [TBXML childElementNamed:kLRTVDBShowIdXMLKey parentElement:showElement];
        TBXMLElement *showNameElement = [TBXML childElementNamed:kLRTVDBShowNameXMLKey parentElement:showElement];
        TBXMLElement *showOverviewElement = [TBXML childElementNamed:kLRTVDBShowOverviewXMLKey parentElement:showElement];
        TBXMLElement *showLanguageElement = [TBXML childElementNamed:kLRTVDBShowLanguageXMLKey parentElement:showElement];
        TBXMLElement *showBannerElement = [TBXML childElementNamed:kLRTVDBShowBannerXMLKey parentElement:showElement];
        TBXMLElement *showPosterElement = [TBXML childElementNamed:kLRTVDBShowPosterXMLKey parentElement:showElement];
        TBXMLElement *showFanartElement = [TBXML childElementNamed:kLRTVDBShowFanartXMLKey parentElement:showElement];
        TBXMLElement *airTimeElement = [TBXML childElementNamed:kLRTVDBShowAirTimeXMLKey parentElement:showElement];
        TBXMLElement *airDayElement = [TBXML childElementNamed:kLRTVDBShowAirDayXMLKey parentElement:showElement];
        TBXMLElement *premiereDateElement = [TBXML childElementNamed:kLRTVDBShowPremiereDateXMLKey parentElement:showElement];
        TBXMLElement *genresElement = [TBXML childElementNamed:kLRTVDBShowGenresXMLKey parentElement:showElement];
        TBXMLElement *actorsNamesElement = [TBXML childElementNamed:kLRTVDBShowActorsXMLKey parentElement:showElement];
        TBXMLElement *imdbIdElement = [TBXML childElementNamed:kLRTVDBShowImdbXMLKey parentElement:showElement];
        TBXMLElement *networkElement = [TBXML childElementNamed:kLRTVDBShowNetworkXMLKey parentElement:showElement];
        TBXMLElement *ratingElement = [TBXML childElementNamed:kLRTVDBShowRatingXMLKey parentElement:showElement];
        TBXMLElement *ratingCountElement = [TBXML childElementNamed:kLRTVDBShowRatingCountXMLKey parentElement:showElement];
        TBXMLElement *contentRatingElement = [TBXML childElementNamed:kLRTVDBShowContentRatingXMLKey parentElement:showElement];
        TBXMLElement *runtimeElement = [TBXML childElementNamed:kLRTVDBShowRuntimeXMLKey parentElement:showElement];
        TBXMLElement *statusElement = [TBXML childElementNamed:kLRTVDBShowBasicStatusXMLKey parentElement:showElement];

        if (showIdElement) show.showID = LREmptyStringToNil([TBXML textForElement:showIdElement]);
        if (showNameElement) show.name = [LREmptyStringToNil([TBXML textForElement:showNameElement]) unescapeHTMLEntities];
        if (showOverviewElement) show.overview = [LREmptyStringToNil([TBXML textForElement:showOverviewElement]) unescapeHTMLEntities];
        if (showLanguageElement) show.language = LREmptyStringToNil([TBXML textForElement:showLanguageElement]);
        if (premiereDateElement) show.premiereDate = [LREmptyStringToNil([TBXML textForElement:premiereDateElement]) dateValue];
        if (showBannerElement) show.bannerURL = LRTVDBImageURLForPath(LREmptyStringToNil([TBXML textForElement:showBannerElement]));
        if (networkElement) show.network = LREmptyStringToNil([TBXML textForElement:networkElement]);
        if (imdbIdElement) show.imdbID = LREmptyStringToNil([TBXML textForElement:imdbIdElement]);
        if (showPosterElement) show.posterURL = LRTVDBImageURLForPath(LREmptyStringToNil([TBXML textForElement:showPosterElement]));
        if (showFanartElement) show.fanartURL = LRTVDBImageURLForPath(LREmptyStringToNil([TBXML textForElement:showFanartElement]));
        if (airTimeElement) show.airTime = LREmptyStringToNil([TBXML textForElement:airTimeElement]);
        if (airDayElement) show.airDay = LREmptyStringToNil([TBXML textForElement:airDayElement]);
        if (genresElement) show.genres = [[LREmptyStringToNil([TBXML textForElement:genresElement]) pipedStringToArray] arrayByRemovingDuplicates];
        if (actorsNamesElement) show.actorsNames = [[LREmptyStringToNil([TBXML textForElement:actorsNamesElement]) pipedStringToArray] arrayByRemovingDuplicates];
        if (ratingElement) show.rating = @([LREmptyStringToNil([TBXML textForElement:ratingElement]) floatValue]);
        if (ratingCountElement) show.ratingCount = @([LREmptyStringToNil([TBXML textForElement:ratingCountElement]) integerValue]);
        if (contentRatingElement) show.contentRating = LREmptyStringToNil([TBXML textForElement:contentRatingElement]);
        if (runtimeElement) show.runtime = LREmptyStringToNil([TBXML textForElement:runtimeElement]);

        if (statusElement)
        {
            NSString *statusString = LREmptyStringToNil([TBXML textForElement:statusElement]);
            
            if ([statusString isEqualToString:kLRTVDBShowBasicStatusContinuingXMLKey])
            {
                show.basicStatus = LRTVDBShowBasicStatusContinuing;
            }
            else if ([statusString isEqualToString:kLRTVDBShowBasicStatusEndedXMLKey])
            {
                show.basicStatus = LRTVDBShowBasicStatusEnded;
            }
        }

        [shows addObject:show];
        
        showElement = [TBXML nextSiblingNamed:kLRTVDBShowSiblingXMLKey searchFromElement:showElement];
    }
    
    return [[self class] removeLanguageDuplicatesFromShows:shows];
}

- (NSArray *)showsIDsFromData:(NSData *)data
{
    NSMutableArray *mutableShowsIDs = [NSMutableArray array];
    
    NSError *error = nil;
    TBXML *tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
    
    TBXMLElement *root = tbxml.rootXMLElement;
    
    if (root && !error)
    {
        TBXMLElement *showElement = [TBXML childElementNamed:kLRTVDBShowSiblingXMLKey parentElement:root];
        
        while (showElement != nil)
        {
            [mutableShowsIDs addObject:[TBXML textForElement:showElement]];
            showElement = [TBXML nextSiblingNamed:kLRTVDBShowSiblingXMLKey searchFromElement:showElement];
        }
    }
    
    return [mutableShowsIDs copy];
}

#pragma mark - Private

+ (NSArray *)removeLanguageDuplicatesFromShows:(NSArray *)showsWithLanguageDuplicates
{
    NSMutableArray *showsWithoutLanguageDuplicates = [NSMutableArray array];
    
    void (^__block __unsafe_unretained removeLanguageDuplicatesBlock)(NSMutableArray *) = ^(NSMutableArray *showsWithLanguageDuplicates) {
        
        if ([showsWithLanguageDuplicates count] == 0) return;
        
        LRTVDBShow *firstShow = [showsWithLanguageDuplicates firstObject];
        
        // Get shows subset with that ID = firstShow.ID
        NSIndexSet *indexSet = [showsWithLanguageDuplicates indexesOfObjectsPassingTest:^BOOL(LRTVDBShow *show, NSUInteger idx, BOOL *stop) {
            return [show isEqual:firstShow];
        }];
        
        NSArray *sameIdShows = [showsWithLanguageDuplicates objectsAtIndexes:indexSet];
        
        __block LRTVDBShow *correctShow = [sameIdShows firstObject];
        
        [sameIdShows enumerateObjectsUsingBlock:^(LRTVDBShow *show, NSUInteger idx, BOOL *stop) {
            
            if ([show.language isEqualToString:[LRTVDBAPIClient sharedClient].language])
            {
                correctShow = show;
                *stop = YES;
            }
            else if ([show.language isEqualToString:LRTVDBDefaultLanguage()])
            {
                correctShow = show;
            }
        }];
        
        [showsWithoutLanguageDuplicates addObject:correctShow];
        [showsWithLanguageDuplicates removeObjectsInArray:sameIdShows];
        
        removeLanguageDuplicatesBlock(showsWithLanguageDuplicates);
    };
    
    removeLanguageDuplicatesBlock([showsWithLanguageDuplicates mutableCopy]);
    
    removeLanguageDuplicatesBlock = nil;
    
    return [showsWithoutLanguageDuplicates copy];
}

static id LRTVDBAPICheckEmptyString(id obj)
{
    BOOL emptyString = [obj isKindOfClass:[NSString class]] &&
                       [(NSString *)obj length] == 0;
    
    return emptyString ? nil : obj;
}

static NSArray *LRTVDBAPICheckArray(id obj)
{
    if (LRTVDBAPICheckEmptyString(obj) == nil)
    {
        return nil;
    }
    else if ([obj isKindOfClass:[NSDictionary class]])
    {
        return @[obj];
    }
    else if ([obj isKindOfClass:[NSArray class]])
    {
        return obj;
    }
    else
    {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Oops! What objects is sending the API!?"];
        return nil;
    }
}

@end
