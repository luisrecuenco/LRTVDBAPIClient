// LRKVCBaseModel.m
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

#import "LRKVCBaseModel.h"
#import "NSString+LRTVDBAdditions.h"

@implementation LRKVCBaseModel

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init])
    {
        // Property - key mapping via KVC
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}

#pragma mark - KVC handling

- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues
{
    // Let's compute the valid mappings. Only map the properties
    // in the mappings property defined in LRKVCBaseModelProtocol.
    NSMutableDictionary *validMappings = [@{} mutableCopy];
    
    [keyedValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
     {
         NSString *objectKey = self.mappings[key];
         
         if (objectKey)
         {
             validMappings[objectKey] = obj;
         }
     }];
    
    [super setValuesForKeysWithDictionary:validMappings];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    // In some weird occasions, the XML we get from the TVDB is wrong formatted
    // and we don't get value being a NSString. Checking for that...
    if ([value isKindOfClass:[NSString class]] && ![NSString isEmptyString:value])
    {
        [super setValue:value forKey:key];
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSAssert(NO, @"Property \"%@\" not found in object of type \"%@\"", key, NSStringFromClass(self.class));
    [super setValue:value forUndefinedKey:key];
}

#pragma mark - LRKVCBaseModelProtocol

- (NSDictionary *)mappings
{
    [NSException raise:NSInternalInconsistencyException
				format:@"%@: Subclasses must override this method and provide the necessary mappings", NSStringFromSelector(_cmd)];
    
    return nil;
}

@end
