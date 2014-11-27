//
//  MessageDate.m
//  StarChatTestProject
//
//  Created by rost on 21.11.14.
//  Copyright (c) 2014 rost. All rights reserved.
//

#import "MessageDate.h"


@implementation MessageDate


#pragma mark - Shared class method
+ (MessageDate *)shared
{
    static MessageDate *shared = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}
#pragma mark -


#pragma mark - getDate:
- (NSString *)getDate:(NSDate *)date {
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MMM dd, yyyy HH:mm"];
    
    return [format stringFromDate:date];
}
#pragma mark -

@end
