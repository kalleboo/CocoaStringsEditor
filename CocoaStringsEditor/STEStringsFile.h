//
//  STEStringsFile.h
//  Strings Editor
//
//  Created by Karl Baron on 2014/05/20.
//  Copyright (c) 2014年 Karl Baron. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSTEStringsFileKey @"key"
#define kSTEStringsFileValue @"value"
#define kSTEStringsFileComment @"comment"

@interface STEStringsFile : NSObject

@property (nonatomic,readonly) NSURL* url;
@property (nonatomic,readonly) NSString* language;
@property (nonatomic,readonly) BOOL parsed;
@property (nonatomic,readonly) BOOL dirty;

-(instancetype)initWithURL:(NSURL*)url;

-(NSArray*)allKeys;
-(NSString*)valueForKey:(NSString*)key;
-(NSString*)commentForKey:(NSString*)key;

-(void)setValue:(id)value forKey:(NSString *)key;
-(void)setComment:(id)comment forKey:(NSString *)key;
-(void)removeKey:(NSString*)key;

-(void)saveFile;
-(void)saveFileToURL:(NSURL*)url;

@end
