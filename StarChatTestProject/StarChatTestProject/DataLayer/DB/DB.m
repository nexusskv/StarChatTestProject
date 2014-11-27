//
//  SQLiteDB.m
//  OS4
//
//  Created by Rostyslav Gress on 19/2/11.
//  Copyright 2011 home. All rights reserved.
//

#import "DB.h"
#import "SKDatabase.h"


NSString* const kLoadArrayWords         = @"SELECT words FROM suggestions";
NSString* const kLoadArraySavedWords    = @"SELECT * FROM messages_history";


@implementation DB

@synthesize db;

#pragma mark - Instance
+ (DB *)shared
{
    static DB *instance = NULL;
    
    @synchronized(self) {
        if (!instance)
            instance = [[self alloc] init];
    }
    
    return instance;
}
#pragma mark -


#pragma mark - Constructors
- (id) init
{
    if(self = [super init]) {
        
    }

    return self;
}

- (void) setDBFileWithName:(NSString *)fileName {
    if (db) {
        [db close];
        db = nil;
    }
    
    db = [[SKDatabase alloc] initWithDynamicFile:fileName];
}
#pragma mark -


#pragma mark - Destructor
- (void)dealloc {
    if (db)
        db = nil;
}
#pragma mark -

@end