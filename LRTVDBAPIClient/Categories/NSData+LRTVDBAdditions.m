// NSData+LRTVDBAdditions.m
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

#import "NSData+LRTVDBAdditions.h"
#import "TBXML.h"

@implementation NSData (LRTVDBAdditions)

- (NSDictionary *)toDictionary
{
    NSError *error = nil;
    TBXML *tbxml = [TBXML newTBXMLWithXMLData:self error:&error];
    TBXMLElement *root = tbxml.rootXMLElement;
    
    return error ? nil : [self dictionaryWithTBXMLElement:root];
}

#pragma mark - Private

- (NSDictionary *)dictionaryWithTBXMLElement:(TBXMLElement *)element
{
    if (!element) return nil;
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    do
    {
        if (element->firstChild)
        {
            if (dictionary[[TBXML elementName:element]] == nil)
            {
                dictionary[[TBXML elementName:element]] = [self dictionaryWithTBXMLElement:element->firstChild];
            }
            else if ([dictionary[[TBXML elementName:element]] isKindOfClass:[NSArray class]])
            {
                [dictionary[[TBXML elementName:element]] addObject:[self dictionaryWithTBXMLElement:element->firstChild]];
            }
            else
            {
                NSMutableArray *elements = [NSMutableArray array];
                [elements addObject:dictionary[[TBXML elementName:element]]];
                [elements addObject:[self dictionaryWithTBXMLElement:element->firstChild]];
                dictionary[[TBXML elementName:element]] = elements;
            }
        }
        else
        {
            dictionary[[TBXML elementName:element]] = [TBXML textForElement:element];
        }
        
    }
    while ((element = element->nextSibling));
    
    return [dictionary copy];
}

@end
