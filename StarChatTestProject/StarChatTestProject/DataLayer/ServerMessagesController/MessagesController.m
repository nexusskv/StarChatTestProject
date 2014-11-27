//
//  MessagesController.m
//  StarChatTestProject
//
//  Created by rost on 19.11.14.
//  Copyright (c) 2014 rost. All rights reserved.
//

#import "MessagesController.h"
#import "Message.h"
#import "MessageDate.h"


@implementation MessagesController


#pragma mark - Shared class method
+ (MessagesController *)shared
{
    static MessagesController *shared = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        shared = [[self alloc] init];
    });
    
    return shared;
}
#pragma mark -


#pragma mark - getPreparedMessages
- (NSArray *)getPreparedMessages {
    NSMutableArray *messages = [NSMutableArray arrayWithArray:[GET_ARRAY_FROM_DB:kLoadArrayWords]];
    
    if ([messages count] > 0) {
        for (int i = 0; i < [messages count]; i++) {
            NSMutableDictionary *freshDictionary = [NSMutableDictionary dictionaryWithDictionary:messages[i]];
            
            if ([[freshDictionary valueForKey:@"words"] rangeOfString:@"#awesome_app"].location != NSNotFound)
                [freshDictionary setObject:@YES forKey:@"appId"];
            else
                [freshDictionary setObject:@NO forKey:@"appId"];
                                
            [messages replaceObjectAtIndex:i withObject:freshDictionary];
        }
    }
    
    return messages;
}
#pragma mark -


#pragma mark - getSavedMesages
- (NSArray *)getSavedMesages {
    NSMutableArray *messages = [NSMutableArray arrayWithArray:[GET_ARRAY_FROM_DB:kLoadArraySavedWords]];
    
    for (int i = 0; i < [messages count]; i++) {
        NSDictionary *message = messages[i];
        
        Message *oldMessage = [[Message alloc] init];
        NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:[message[@"date"] doubleValue]];
        oldMessage.message = [NSString stringWithFormat:@"%@ \n %@", [[MessageDate shared] getDate:messageDate], message[@"message"]];
        oldMessage.typeMessage = [message[@"message_type"] integerValue];
        oldMessage.appIdFlag = [message[@"app_id_flag"] boolValue];

        [messages replaceObjectAtIndex:i withObject:oldMessage];
    }
    
    return messages;
}
#pragma mark -

@end
