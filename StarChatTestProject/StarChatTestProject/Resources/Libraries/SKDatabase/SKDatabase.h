//
//  SKDatabase.h
//  Version 1.1
//
//  Created by Shannon Appelcline on 9/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

@protocol SKDatabaseDelegate <NSObject>
@optional
- (void)databaseTableWasUpdated:(NSString *)table;
@end

@interface SKDatabase : NSObject {
	
	__weak id<SKDatabaseDelegate> delegate;
	sqlite3 *dbh;
	BOOL dynamic;
}

@property (weak) id<SKDatabaseDelegate> delegate;
@property sqlite3 *dbh;
@property BOOL dynamic;

- (id)initWithDynamicFile:(NSString *)dbFile;
- (void)close;

- (NSArray *)lookupAllForSQL:(NSString *)sql;
- (void)insertDictionary:(NSDictionary *)dbData forTable:(NSString *)table;

@end



