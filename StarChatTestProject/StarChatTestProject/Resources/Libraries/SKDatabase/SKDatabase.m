//
//  SKDatabase.m
//  Version 1.1
//
//  Created by Shannon Appelcline on 9/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//


#import "SKDatabase.h"


@implementation SKDatabase

@synthesize delegate;
@synthesize dbh;
@synthesize dynamic;


- (id)initWithDynamicFile:(NSString *)dbFile {
	if (self = [super init]) {
		
		NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *docDir = [docPaths objectAtIndex:0];
		NSString *docPath = [docDir stringByAppendingPathComponent:dbFile];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		NSError *error;

		if (![fileManager fileExistsAtPath:docPath]) {
			
			NSString *origPaths = [[NSBundle mainBundle] resourcePath];
			NSString *origPath = [origPaths stringByAppendingPathComponent:dbFile];

			int success = [fileManager copyItemAtPath:origPath toPath:docPath error:&error];			
			NSAssert1(success, @"Failed to copy database into dynamic location", error);

			NSLog(@"%d", success);
		}
		int result = sqlite3_open([docPath UTF8String], &dbh);
		if(result == SQLITE_OK) {
			NSLog(@"Successfully opened database");
		}
		NSAssert1(SQLITE_OK == result, NSLocalizedStringFromTable(@"Unable to open the sqlite database (%@).", @"Database", @""), [NSString stringWithUTF8String:sqlite3_errmsg(dbh)]);	
		self.dynamic = YES;
	}
	
	return self;	
}

- (NSArray *)lookupAllForSQL:(NSString *)sql {
	id cBoxedColumnValue = nil;
	sqlite3_stmt *pStmt = [self prepare:sql];
	const void *cColumnBlobVal;	
	NSMutableArray *thisArray = [NSMutableArray arrayWithCapacity:4];
	if (pStmt) {
		while (sqlite3_step(pStmt) == SQLITE_ROW) {	
			int theColumnCount = sqlite3_column_count(pStmt);
			NSMutableDictionary *thisDict = [NSMutableDictionary dictionaryWithCapacity:theColumnCount];
			for (int theColumn = 0 ; theColumn < theColumnCount; theColumn++) {
				@try {
					int cColumnType = sqlite3_column_type(pStmt, theColumn);
					const char *cColumnName = sqlite3_column_name(pStmt, theColumn);
					
					switch(cColumnType)
					{
						case SQLITE_INTEGER:
							cBoxedColumnValue = [NSNumber numberWithInteger:sqlite3_column_int(pStmt, theColumn)];
							break;
						case SQLITE_FLOAT:
							cBoxedColumnValue = [NSNumber numberWithDouble:sqlite3_column_double(pStmt, theColumn)];
							break;
						case SQLITE_BLOB:
							cColumnBlobVal = sqlite3_column_blob(pStmt, theColumn);
							int cColumnBlobValLen = sqlite3_column_bytes(pStmt, theColumn);
							cBoxedColumnValue = [NSData dataWithBytes:cColumnBlobVal length:cColumnBlobValLen];
							break;
						case SQLITE_NULL:
							cBoxedColumnValue = nil;
							break;
						case SQLITE_TEXT:
							cBoxedColumnValue = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(pStmt, theColumn)];
							break;
					}
					
					if(cBoxedColumnValue != nil) {
						[thisDict setObject:cBoxedColumnValue forKey:[NSString stringWithUTF8String:cColumnName]];
					}
				} @catch (NSException *exception) {
					NSLog(@"Exception while processing column in lookupRowForSQL");
				}
			}
			
			[thisArray addObject:[NSDictionary dictionaryWithDictionary:thisDict]];
		}
	}
	sqlite3_finalize(pStmt);
	return thisArray;
}

- (void)insertDictionary:(NSDictionary *)dbData forTable:(NSString *)table {
    NSMutableString *sql = [NSMutableString stringWithCapacity:16];
    [sql appendFormat:@"INSERT INTO %@ (",table];
    
    NSArray *dataKeys = [dbData allKeys];
    for (int i = 0 ; i < [dataKeys count] ; i++) {
        [sql appendFormat:@"%@",[dataKeys objectAtIndex:i]];
        if (i + 1 < [dbData count]) {
            [sql appendFormat:@", "];
        }
    }
    
    [sql appendFormat:@") VALUES("];
    for (int i = 0 ; i < [dataKeys count] ; i++) {
        id objValue = [dbData objectForKey:[dataKeys objectAtIndex:i]];
        if ([objValue isKindOfClass:[NSNumber class]]) {
            [sql appendFormat:@"%@",[dbData objectForKey:[dataKeys objectAtIndex:i]]];
        } else {
            [sql appendFormat:@"'%@'",[self sqlSafeString:[dbData objectForKey:[dataKeys objectAtIndex:i]]]];
        }
        if (i + 1 < [dbData count]) {
            [sql appendFormat:@", "];
        }
    }
    
    [sql appendFormat:@")"];
    [self runDynamicSQL:sql forTable:table];
}

- (sqlite3_stmt *)prepare:(NSString *)sql {
    const char *utfsql = [sql UTF8String];
    
    sqlite3_stmt *statement;
    
    int retCode = sqlite3_prepare_v2([self dbh],utfsql,-1,&statement,NULL);
    if (retCode == SQLITE_OK) {
        return statement;
    } else {
        return 0;
    }
}

- (BOOL)runDynamicSQL:(NSString *)sql forTable:(NSString *)table {
    int result = 0;
    NSAssert1(self.dynamic == 1,@"Use a dynamic function on a static database",NULL);
    sqlite3_stmt *statement = nil;
    statement = [self prepare:sql];
    if (statement)
    {
        result = sqlite3_step(statement);
    }
    sqlite3_finalize(statement);
    if (result) {
        if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(databaseTableWasUpdated:)]) {
            [delegate databaseTableWasUpdated:table];
        }
        return YES;
    } else {
        return NO;
    }    
}

- (NSString *)sqlSafeString:(NSString *)value {
    if(value && [value respondsToSelector:@selector(stringByReplacingOccurrencesOfString:withString:)]) {
        return [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    } else {
        return value;
    }
}

- (void)dealloc {
	[self close];
}

- (void)close {	
	if (dbh) {
		sqlite3_close(dbh);
	}
}

@end