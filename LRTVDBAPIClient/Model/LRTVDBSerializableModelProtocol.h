// LRTVDBSerializableModelProtocol.h
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

#import <Foundation/Foundation.h>

// NSPropertyListSerialization compatibility
NS_INLINE id LRNilToEmptyString(id obj)
{
    return obj ? : @"";
}

NS_INLINE id LREmptyStringToNil(id obj)
{
    return [obj isEqual:@""] ? nil : obj;
}

static NSString *const kPlistTypeErrorDomain = @"kPlistTypeErrorDomain";
static NSString *const kPlistTypeErrorKeyName = @"kPlistTypeErrorKeyName";

typedef NS_ENUM (NSUInteger, PlistError)
{
    kPlistMissingKeyError,
    kPlistBadTypeError,
};

#define CHECK_NIL(variable, key, outError) \
if(!(variable)) { \
if((outError)) \
outError = [NSError errorWithDomain: kPlistTypeErrorDomain code: kPlistMissingKeyError userInfo: @{ kPlistTypeErrorKeyName : (key) }]; \
NSLog(@"Plist Error: %@ is nil", key); \
return nil; \
}

#define CHECK_TYPE(variable, type, key, outError) \
if((variable)) { \
if(![(variable) isKindOfClass: (type)]) { \
if((outError)) \
outError = [NSError errorWithDomain: kPlistTypeErrorDomain code: kPlistBadTypeError userInfo: @{ kPlistTypeErrorKeyName : (key) }]; \
NSLog(@"Plist Error: %@ is not of class type %@, is of class %@", key, NSStringFromClass(type), NSStringFromClass([(variable) class])); \
return nil; \
} \
}

#define CHECK_TYPES(variable, type1, type2, key, outError) \
if((variable)) { \
if(![(variable) isKindOfClass: (type1)] && ![(variable) isKindOfClass: (type2)]) { \
if((outError)) \
outError = [NSError errorWithDomain: kPlistTypeErrorDomain code: kPlistBadTypeError userInfo: @{ kPlistTypeErrorKeyName : (key) }]; \
NSLog(@"Plist Error: %@ is not of class type %@, not of class type %@, is of class %@", key, NSStringFromClass(type1), NSStringFromClass(type2), NSStringFromClass([(variable) class])); \
return nil; \
} \
}

@protocol LRTVDBSerializableModelProtocol <NSObject>

+ (id<LRTVDBSerializableModelProtocol>)deserialize:(NSDictionary *)dictionary error:(NSError **)error;
- (NSDictionary *)serialize;

@end
