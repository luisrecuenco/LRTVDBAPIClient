//
//  LRTVDBBaseModel+Private.h
//  LRTVDBAPIClientExample
//
//  Created by Luis Recuenco on 21/01/13.
//  Copyright (c) 2013 Luis Recuenco. All rights reserved.
//

#import "LRTVDBBaseModel.h"

@interface LRTVDBBaseModel (Private)

/**
 Used by subclasses for persistence purposes.
 */
@property (nonatomic, strong) NSDictionary *persistenceDictionary;

@end
