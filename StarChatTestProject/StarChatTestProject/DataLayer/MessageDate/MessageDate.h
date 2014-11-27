//
//  MessageDate.h
//  StarChatTestProject
//
//  Created by rost on 21.11.14.
//  Copyright (c) 2014 rost. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageDate : NSObject

+ (MessageDate *)shared;

- (NSString *)getDate:(NSDate *)date;

@end
