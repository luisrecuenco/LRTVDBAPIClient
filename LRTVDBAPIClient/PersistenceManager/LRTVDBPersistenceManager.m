// LRTVDBPersistenceManager.m
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

#import "LRTVDBPersistenceManager.h"
#import "LRTVDBShow.h"
#import "NSArray+LRTVDBAdditions.h"

static NSString *const kLRTVDBShowsPeristenceFileName = @"LRTVDBShowsPersistenceFile";

@implementation LRTVDBPersistenceManager

+ (instancetype)manager
{
    return [[self alloc] init];
}

- (void)saveShowsInPersistenceStorage:(NSArray *)shows error:(__autoreleasing NSError **)error
{
    NSData *plistData = [self peristenceFileForShows:shows error:error];
    
    if (!plistData || *error)
    {
        return;
    }
    
    BOOL success = [plistData writeToFile:[self showsStoragePath]
                                  options:NSDataWritingAtomic
                                    error:error];
    
    if(!success || *error)
    {
        NSLog(@"Unable to write plist data to disk: %@", *error);
    }
}

- (NSData *)peristenceFileForShows:(NSArray *)shows error:(__autoreleasing NSError **)error
{
    NSMutableArray *mutableShows = [NSMutableArray arrayWithCapacity:[shows count]];
    
    for (LRTVDBShow *show in shows)
    {
        [mutableShows addObject:[show serialize]];
    }
    
    NSData *plistData = [NSPropertyListSerialization
                         dataWithPropertyList:mutableShows
                         format:NSPropertyListBinaryFormat_v1_0
                         options:0
                         error:error];
    
    if(!plistData || *error)
    {
        NSLog(@"Unable to generate plist data from shows: %@", *error);
        return nil;
    }
    else
    {
        return plistData;
    }
}

- (NSArray *)showsFromPersistenceStorageWithError:(__autoreleasing NSError **)error
{
    NSData *plistData = [NSData dataWithContentsOfFile:[self showsStoragePath]
                                               options:0
                                                 error:error];
    
    if(!plistData || *error)
    {
        NSLog(@"Unable to read plist data from disk: %@", *error);
        return nil;
    }
    else
    {
        return [self showsFromData:plistData error:error];
    }
}

- (NSArray *)showsFromData:(NSData *)data error:(__autoreleasing NSError **)error
{
    NSArray *serializedEntries = [NSPropertyListSerialization propertyListWithData:data
                                                                           options:0
                                                                            format:NULL
                                                                             error:error];
    if(!serializedEntries || *error)
    {
        NSLog(@"Unable to decode plist from data: %@", *error);
        return nil;
    }
    
    NSMutableArray *mutableShows = [NSMutableArray arrayWithCapacity:[serializedEntries count]];
    
    for (NSDictionary *serializedEntry in serializedEntries)
    {
        NSError *error = nil;
        
        LRTVDBShow *show = [LRTVDBShow deserialize:serializedEntry error:&error];
        
        if (show)
        {
            [mutableShows addObject:show];
        }
    }
    
    return [mutableShows copy];
}

#pragma mark - Peristence File URL

- (NSString *)showsStoragePath
{
    NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    return [docsDirectory stringByAppendingPathComponent:kLRTVDBShowsPeristenceFileName];
}

@end
