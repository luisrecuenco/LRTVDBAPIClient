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

- (void)saveShowsInPersistenceStorage:(NSArray *)shows
{
    NSMutableArray *mutableShows = [NSMutableArray arrayWithCapacity:[shows count]];
    
    [shows enumerateObjectsUsingBlock:^(LRTVDBShow *show, NSUInteger idx, BOOL *stop) {
        NSDictionary *serializedEntry = [show serialize];
        [mutableShows addObject:serializedEntry];
    }];
    
    NSError* error = nil;
    NSData *dictionaryData = [NSPropertyListSerialization
                              dataWithPropertyList:mutableShows
                              format:NSPropertyListBinaryFormat_v1_0
                              options:0
                              error:&error];
    
    if (!error)
    {
        [dictionaryData writeToFile:[self showsStoragePath]
                            options:NSDataWritingAtomic
                              error:&error];
    }
}

- (NSArray *)showsFromPersistenceStorage
{
    NSData *dictionaryData = [NSData dataWithContentsOfFile:[self showsStoragePath]];
    
    if (dictionaryData == nil) return nil;
    
    NSString *error = nil;
    NSArray *serializedEntries = [NSPropertyListSerialization propertyListFromData:dictionaryData
                                                                  mutabilityOption:NSPropertyListImmutable
                                                                            format:nil
                                                                  errorDescription:&error];
    
    NSMutableArray *mutableShows = [NSMutableArray arrayWithCapacity:[serializedEntries count]];
    
    if (!error)
    {
        [serializedEntries enumerateObjectsUsingBlock:^(NSDictionary *serializedEntry, NSUInteger idx, BOOL *stop) {
            LRTVDBShow *show = (LRTVDBShow *)[LRTVDBShow deserialize:serializedEntry];
            [mutableShows addObject:show];
        }];
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
