// LRShowStorage.m
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

#import "LRTVDBShowStorage.h"
#import "LRTVDBShow.h"
#import "LRTVDBPersistenceManager.h"

@interface LRTVDBShowStorage ()

@property (nonatomic, copy) NSArray *shows;
@property (nonatomic, strong) NSMutableArray *mutableShows;
@property (nonatomic, strong) NSMutableDictionary *mutableShowsMap;

@end

@implementation LRTVDBShowStorage

+ (LRTVDBShowStorage *)sharedStorage
{
    static LRTVDBShowStorage *sharedStorage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStorage = [[self alloc] init];
    });
    
    return sharedStorage;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        NSArray *persistedShows = [[LRTVDBPersistenceManager manager] showsFromPersistenceStorage];
        
        for (LRTVDBShow *show in persistedShows)
        {
            [self addShow:show];
        }
        
        // Save shows when entering background
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:[UIApplication sharedApplication]];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Add Show

- (void)addShow:(LRTVDBShow *)show
{
    if ([self existShow:show]) return;

    NSUInteger index = [self.mutableShows indexOfObject:show
                                          inSortedRange:NSMakeRange(0, self.mutableShows.count)
                                                options:NSBinarySearchingInsertionIndex
                                        usingComparator:LRTVDBShowComparator];
    
    [self.mutableShows insertObject:show atIndex:index];
    self.mutableShowsMap[show.showID] = show;
    
    self.shows = nil; // Regenerate
    
    if ([self.delegate respondsToSelector:@selector(showStorageDidAddShow:)])
    {
        [self.delegate showStorageDidAddShow:show];
    }
    
    if (show.episodes == nil)
    {
        [show addObserver:self
               forKeyPath:LRTVDBShowAttributes.episodes
                  options:0
                  context:NULL];
    }
}

#pragma mark - Remove Show

- (void)removeShow:(LRTVDBShow *)show
{
    if (![self existShow:show]) return;
        
    [self.mutableShows removeObject:show];
    [self.mutableShowsMap removeObjectForKey:show.showID];
    
    self.shows = nil; // Regenerate
    
    if ([self.delegate respondsToSelector:@selector(showStorageDidDeleteShow:)])
    {
        [self.delegate showStorageDidDeleteShow:show];
    }
}

#pragma mark - KVO for shows that have not been updated yet

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(LRTVDBShow *)show
                        change:(NSDictionary *)change
                       context:(void *)context
{
    [self.mutableShows removeObject:show];
    
    NSUInteger index = [self.mutableShows indexOfObject:show
                                          inSortedRange:NSMakeRange(0, self.mutableShows.count)
                                                options:NSBinarySearchingInsertionIndex
                                        usingComparator:LRTVDBShowComparator];
    
    [self.mutableShows insertObject:show atIndex:index];
    
    self.shows = nil;
    
    if ([self.delegate respondsToSelector:@selector(showStorageDidUpdateShow:)])
    {
        [self.delegate showStorageDidUpdateShow:show];
    }
    
    [show removeObserver:self forKeyPath:LRTVDBShowAttributes.episodes];
}

#pragma mark - Show for ID

- (LRTVDBShow *)showForID:(NSString *)showID
{
    return self.mutableShowsMap[showID];
}

- (BOOL)existShow:(LRTVDBShow *)show
{
    return [self showForID:show.showID] != nil;
}

- (NSArray *)shows
{
    if (_shows == nil)
    {
        _shows = [self.mutableShows copy];
    }
    return _shows;
}

- (void)reloadShows
{
    [self.mutableShows sortUsingComparator:LRTVDBShowComparator];
    
    self.shows = nil;
}

#pragma mark - Lazy getters

- (NSMutableArray *)mutableShows
{
    if (_mutableShows == nil)
    {
        _mutableShows = [NSMutableArray array];
    }
    return _mutableShows;
}

- (NSMutableDictionary *)mutableShowsMap
{
    if (_mutableShowsMap == nil)
    {
        _mutableShowsMap = [NSMutableDictionary dictionary];
    }
    return _mutableShowsMap;
}

#pragma mark - Persistence

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [[LRTVDBPersistenceManager manager] saveShowsInPersistenceStorage:self.mutableShows];
}

@end
