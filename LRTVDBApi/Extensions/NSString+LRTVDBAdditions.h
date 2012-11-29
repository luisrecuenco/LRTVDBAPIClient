// NSString+LRTVDBAdditions.h
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

#import <Foundation/Foundation.h>

@interface NSString (LRTVDBAdditions)

@property (nonatomic, readonly) NSDate *dateValue;

/**
 Basic HTML unescaping.
 @return A new NSString after unescaping the HTML entities.
 */
- (NSString *)unescapeHTMLEntities;

/**
 Turn a NSString similar to |Foo|Bar|...| into something like @[@"Foo", @"Bar",...].
 @return A new NSArray with the aforementioned transform.
 */
- (NSArray *)pipedStringToArray;

/**
 Check for empty string.
 @param string The NSString to be checked.
 @discussion The reason behind creating a class method with the string
 to check as an argument instead of a property or an instance method and check
 for self is that, if self is nil, [string isEmpty] = NO as the method wouldn't
 be called.
 @return YES if the receiver is empty, NO otherwise.
 */
+ (BOOL)isEmptyString:(NSString *)string;

@end
