// NSString+LRTVDBAdditions.m
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

#import "NSString+LRTVDBAdditions.h"

@implementation NSString (LRTVDBAdditions)

- (NSDate *)dateValue
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    });
    
    return [dateFormatter dateFromString:self];
}

- (NSString *)unescapeHTMLEntities
{
    NSString *unescapedString = [self stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    unescapedString = [unescapedString stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
    unescapedString = [unescapedString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    unescapedString = [unescapedString stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    unescapedString = [unescapedString stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    
    return unescapedString;
}

+ (BOOL)isEmptyString:(NSString *)string
{
    BOOL empty = (NSNull *)string == [NSNull null] || string == 0;
    
    if (empty == NO)
    {
        NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        empty = trimmedString.length == 0;
    }
    
    return empty;
}

@end
