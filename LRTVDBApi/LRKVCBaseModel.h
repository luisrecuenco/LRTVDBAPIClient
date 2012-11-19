// LRKVCBaseModel.h
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

#pragma mark - LRKVCBaseModel Protocol definition

@protocol LRKVCBaseModelProtocol <NSObject>

/**
 Dictionary with the correct mappings (@{key : propertyName}).
 */
@property (nonatomic, readonly) NSDictionary *mappings;

@end

#pragma mark - LRKVCBaseModel Interface definition

@interface LRKVCBaseModel : NSObject <LRKVCBaseModelProtocol>

/**
 Creates a new object via KVC.
 
 @param dictionary NSDictionary with the correct mappings (@{ key : value }).
 Via KVC, the object must have a property whose name is exactly the same as
 'key'. Thus, 'value' will be attached to that property.
 
 @discussion Forcing the object to have the very same property names
 as the keys in the dictionary may not be the best idea.
 In order to be able to have an object whose property names are different
 from the keys in the dictionary, the 'mappings' property defined in
 LRKVCBaseModelProtocol must be provided.
 
 Example:
 
 dictionary: _KEY_ : value
 
 object: property 'key'
 
 The object class (sublcass of LRKVCBaseModel) must have:
 
 - (NSDictionary *)mappings
 {
     return @{ @"_KEY_" : @"key" };
 }
 
 Thus, we'll have a property 'key' whose value is 'value'.
 
 @return A new LRKVCBaseModel object.
 */
- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
