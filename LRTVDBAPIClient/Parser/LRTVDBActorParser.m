// LRTVDBActorParser.m
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
#import "LRTVDBActor+Private.h"
#import "LRTVDBActorParser.h"
#import "NSString+LRTVDBAdditions.h"
#import "TBXML.h"

// XML keys
static NSString *const kLRTVDBActorSiblingXMLKey = @"Actor";
static NSString *const kLRTVDBActorIdXMLKey = @"id";
static NSString *const kLRTVDBActorNameXMLKey = @"Name";
static NSString *const kLRTVDBActorRoleXMLKey = @"Role";
static NSString *const kLRTVDBActorImageXMLKey = @"Image";
static NSString *const kLRTVDBActorSortOrderXMLKey = @"SortOrder";

@implementation LRTVDBActorParser

+ (instancetype)parser
{
    return [[self alloc] init];
}

- (NSArray *)actorsFromData:(NSData *)data
{    
    NSError *error = nil;
    TBXML *tbxml = [TBXML newTBXMLWithXMLData:data error:&error];
    TBXMLElement *root = tbxml.rootXMLElement;
    
    if (error || !root) return nil;
    
    TBXMLElement *actorElement = [TBXML childElementNamed:kLRTVDBActorSiblingXMLKey parentElement:root];
    
    NSMutableArray *actors = [NSMutableArray array];
    
    while (actorElement != nil)
    {
        LRTVDBActor *actor = [[LRTVDBActor alloc] init];
 
        TBXMLElement *actorIdElement = [TBXML childElementNamed:kLRTVDBActorIdXMLKey parentElement:actorElement];
        TBXMLElement *actorNameElement = [TBXML childElementNamed:kLRTVDBActorNameXMLKey parentElement:actorElement];
        TBXMLElement *actorRoleElement = [TBXML childElementNamed:kLRTVDBActorRoleXMLKey parentElement:actorElement];
        TBXMLElement *actorImageElement = [TBXML childElementNamed:kLRTVDBActorImageXMLKey parentElement:actorElement];
        TBXMLElement *actorSortOrderElement = [TBXML childElementNamed:kLRTVDBActorSortOrderXMLKey parentElement:actorElement];

        if (actorIdElement) actor.actorID = LREmptyStringToNil([TBXML textForElement:actorIdElement]);
        if (actorNameElement) actor.name = [LREmptyStringToNil([TBXML textForElement:actorNameElement]) unescapeHTMLEntities];
        if (actorRoleElement) actor.role = [LREmptyStringToNil([TBXML textForElement:actorRoleElement]) unescapeHTMLEntities];
        if (actorImageElement) actor.imageURL = LRTVDBImageURLForPath(LREmptyStringToNil([TBXML textForElement:actorImageElement]));
        if (actorSortOrderElement) actor.sortOrder = @([LREmptyStringToNil([TBXML textForElement:actorSortOrderElement]) integerValue]);

        [actors addObject:actor];
        
        actorElement = [TBXML nextSiblingNamed:kLRTVDBActorSiblingXMLKey searchFromElement:actorElement];
    }

    return [actors copy];
}

@end
