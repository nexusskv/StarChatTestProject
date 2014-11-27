//
//  MessagesController.h
//  StarChatTestProject
//
//  Created by rost on 19.11.14.
//  Copyright (c) 2014 rost. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessagesController : NSObject

+ (MessagesController *)shared;

- (NSArray *)getPreparedMessages;
- (NSArray *)getSavedMesages;
@end
