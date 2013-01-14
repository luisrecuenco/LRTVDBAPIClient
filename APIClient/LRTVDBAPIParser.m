// LRTVDBAPIParser.m
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

#import "LRTVDBAPIParser.h"
#import "LRTVDBShow.h"
#import "NSArray+LRTVDBAdditions.h"
#import "LRTVDBAPIClient.h"
#import "LRTVDBAPIClient+Private.h"
#import "LRTVDBEpisode.h"
#import "LRTVDBImage.h"
#import "LRTVDBActor.h"
#import "TBXML.h"

/** XML Tags */
static NSString *const kXMLDataTagName = @"Data";
static NSString *const kXMLSeriesTagName = @"Series";
static NSString *const kXMLEpisodesTagName = @"Episode";
static NSString *const kXMLBannersTagName = @"Banners";
static NSString *const kXMLBannerTagName = @"Banner";
static NSString *const kXMLActorsTagName = @"Actors";
static NSString *const kXMLActorTagName = @"Actor";

@implementation LRTVDBAPIParser

+ (instancetype)parser
{
    return [[self alloc] init];
}

- (NSArray *)showsFromDictionary:(NSDictionary *)dictionary
{
    NSArray *showsWithoutLanguageDuplicates = @[];
    
    if ([dictionary[kXMLDataTagName] respondsToSelector:@selector(objectForKey:)])
    {
        NSArray *showsArrayOfDictionaries = LRTVDBAPICheckArray(dictionary[kXMLDataTagName][kXMLSeriesTagName]);
        NSArray *showsWithLanguageDuplicates = [[self class] showsFromArray:showsArrayOfDictionaries];
        showsWithoutLanguageDuplicates = [self removeLanguageDuplicatesFromShows:showsWithLanguageDuplicates];
    }
    
    return showsWithoutLanguageDuplicates;
}

- (NSArray *)episodesFromDictionary:(NSDictionary *)dictionary
{
    NSArray *episodes = @[];
    
    if ([dictionary[kXMLDataTagName] respondsToSelector:@selector(objectForKey:)])
    {
        NSArray *episodesArrayOfDictionaries = LRTVDBAPICheckArray(dictionary[kXMLDataTagName][kXMLEpisodesTagName]);
        episodes = [[self class] episodesFromArray:episodesArrayOfDictionaries];
        
        if ([LRTVDBAPIClient sharedClient].includeSpecials == NO)
        {
            NSIndexSet *indexSet = [episodes indexesOfObjectsPassingTest:^BOOL(LRTVDBEpisode *episode, NSUInteger idx, BOOL *stop) {
                return [episode.seasonNumber compare:@(0)] == NSOrderedDescending;
            }];
            
            episodes = [episodes objectsAtIndexes:indexSet];
        }
    }
    
    return episodes;
}

- (NSArray *)imagesFromDictionary:(NSDictionary *)dictionary
{
    NSArray *images = @[];
    
    if ([dictionary[kXMLBannersTagName] respondsToSelector:@selector(objectForKey:)])
    {
        NSArray *imagesArrayOfDictionaries = LRTVDBAPICheckArray(dictionary[kXMLBannersTagName][kXMLBannerTagName]);
        images = [[self class] imagesFromArray:imagesArrayOfDictionaries];
    }
    
    return images;
}

- (NSArray *)actorsFromDictionary:(NSDictionary *)dictionary
{
    NSArray *actors = @[];
    
    if ([dictionary[kXMLActorsTagName] respondsToSelector:@selector(objectForKey:)])
    {
        NSArray *actorsArrayOfDictionaries = LRTVDBAPICheckArray(dictionary[kXMLActorsTagName][kXMLActorTagName]);
        actors = [[self class] actorsFromArray:actorsArrayOfDictionaries];        
    }

    return actors;
}

- (NSArray *)showsIDsFromData:(NSData *)data
{
    NSMutableArray *mutableShowsIDs = [NSMutableArray array];
    
    NSError *error = nil;
    TBXML *tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
    
    TBXMLElement *root = tbxml.rootXMLElement;
    
    if (root && !error)
    {
        TBXMLElement *series = [TBXML childElementNamed:kXMLSeriesTagName parentElement:root];
        
        while (series != nil)
        {
            [mutableShowsIDs addObject:[TBXML textForElement:series]];
            series = [TBXML nextSiblingNamed:kXMLSeriesTagName searchFromElement:series];
        }
    }
    
    return [mutableShowsIDs copy];
}

- (NSArray *)episodesIDsFromData:(NSData *)data
{
    NSMutableArray *mutableEpisodesIDs = [NSMutableArray array];
    
    NSError *error = nil;
    TBXML *tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
    
    TBXMLElement *root = tbxml.rootXMLElement;
    
    if (root && !error)
    {        
        TBXMLElement *episodes = [TBXML childElementNamed:kXMLEpisodesTagName parentElement:root];
        
        while (episodes != nil)
        {
            [mutableEpisodesIDs addObject:[TBXML textForElement:episodes]];
            episodes = [TBXML nextSiblingNamed:kXMLEpisodesTagName searchFromElement:episodes];
        }
    }
    
    return [mutableEpisodesIDs copy];
}

#pragma mark - Private

typedef LRBaseModel *(^LRBaseModelDictionaryBlock)(NSDictionary *);

+ (NSArray *)objectsFromArray:(NSArray *)array
              objectTypeBlock:(LRBaseModelDictionaryBlock)block
{
    NSMutableArray *objects = [NSMutableArray array];
    
    for (NSDictionary *dict in array)
    {
        id obj = block(dict);
       
        if (obj)
        {
            [objects addObject:obj];
        }
    }
    
    return [objects copy];
}

+ (NSArray *)showsFromArray:(NSArray *)shows
{
    return [self objectsFromArray:shows
                  objectTypeBlock:^(NSDictionary *showDictionary){
                      return [LRTVDBShow showWithDictionary:showDictionary];
                  }];
}

+ (NSArray *)episodesFromArray:(NSArray *)episodes
{
    return [self objectsFromArray:episodes
                  objectTypeBlock:^(NSDictionary *episodeDictionary){
                      return [LRTVDBEpisode episodeWithDictionary:episodeDictionary];
                  }];
}

+ (NSArray *)imagesFromArray:(NSArray *)images
{
    return [self objectsFromArray:images
                  objectTypeBlock:^(NSDictionary *imageDictionary){
                      return [LRTVDBImage imageWithDictionary:imageDictionary];
                  }];
}

+ (NSArray *)actorsFromArray:(NSArray *)actors
{
    return [self objectsFromArray:actors
                  objectTypeBlock:^(NSDictionary *actorsDictionary){
                      return [LRTVDBActor actorWithDictionary:actorsDictionary];
                  }];
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

- (NSArray *)removeLanguageDuplicatesFromShows:(NSArray *)showsWithLanguageDuplicates
{
    NSMutableArray *showsWithoutLanguageDuplicates = [NSMutableArray array];
    
    void (^__block removeLanguageDuplicatesBlock)(NSMutableArray *) = ^(NSMutableArray *showsWithLanguageDuplicates){
        
        if (showsWithLanguageDuplicates.count == 0) return;
        
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
    
    return [showsWithoutLanguageDuplicates copy];
}

@end
