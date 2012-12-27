// LRTVDBActor.h
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

/**
 Actor comparison block.
 */
extern NSComparator LRTVDBActorComparator;

@interface LRTVDBActor : LRKVCBaseModel

@property (nonatomic, copy, readonly) NSString *actorID;

/** Real actor name. */
@property (nonatomic, copy, readonly) NSString *name;

/** Character name. */
@property (nonatomic, copy, readonly) NSString *role;

/** Example: http:/www.thetvdb.com/banners/actors/77049.jpg. */
@property (nonatomic, strong, readonly) NSURL *artworkURL;

/** Number to be used when sorting different actors, i.e, 0 -> most important actor. */
@property (nonatomic, strong, readonly) NSNumber *sortOrder;

/**
 Creates a new actor.
 @see LRKVCBaseModel initializer for more info.
 */
+ (instancetype)actorWithDictionary:(NSDictionary *)dictionary;

@end
