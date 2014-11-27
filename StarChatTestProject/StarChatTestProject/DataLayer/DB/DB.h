//
//  SQLiteDB.h
//  OS4
//
//  Created by Rostyslav Gress on 19/2/11.
//  Copyright 2011 home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKDatabase.h"


#define GET_ARRAY_FROM_DB       [DB shared].db lookupAllForSQL
#define SAVE_DICTIONARY(a)      [DB shared].db insertDictionary:(a) forTable:@"messages_history"


extern NSString* const kLoadArrayWords;
extern NSString* const kLoadArraySavedWords;


@interface DB : NSObject

@property (nonatomic, readonly) SKDatabase *db;
    
+ (DB *)shared;
- (void)setDBFileWithName:(NSString *)fileName;
@end