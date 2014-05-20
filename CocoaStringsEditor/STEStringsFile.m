//
//  STEStringsFile.m
//  Strings Editor
//
//  Created by Karl Baron on 2014/05/20.
//  Copyright (c) 2014年 Karl Baron. All rights reserved.
//

#import "STEStringsFile.h"

@interface STEStringsFile ()
{
    BOOL _parsed;
    BOOL _dirty;
    NSString* _language;
    NSURL* _url;
}

@property (nonatomic,strong) NSMutableArray* keys;
@property (nonatomic,strong) NSMutableDictionary* values;
@property (nonatomic,strong) NSMutableDictionary* comments;

-(void)parseFile;

@end

@implementation STEStringsFile

-(instancetype)initWithURL:(NSURL*)url {
    self = [super init];
    
    if (self) {
        _url = url;
        NSURL* parentDir = [url URLByDeletingLastPathComponent];
        _language = [parentDir lastPathComponent];
    }
    
    return self;
}

#pragma mark - File read/write
/*
 this is currently a hack and there must be a better way (one of the command line tools? or is this an old-style plist?)
 will not handle files not perfectly formatted, and some string contents may confuse it (splits string on " = ")
 */
-(void)parseFile {
    if (_parsed)
        return;
    
    NSMutableArray* parsedKeys = [NSMutableArray array];
    NSMutableDictionary* parsedValues = [NSMutableDictionary dictionary];
    NSMutableDictionary* parsedComments = [NSMutableDictionary dictionary];
    
    NSLog(@"parsing file url %@",self.url);
    
    NSString* string = [NSString stringWithContentsOfURL:self.url encoding:NSUTF16StringEncoding error:nil];
    NSArray* lines = [string componentsSeparatedByString:@"\n"];
    
    NSString* currentComment = nil;
    BOOL commentTrail = FALSE;
    
    for (int i = 0; i<[lines count]; i++) {
        NSString* line = lines[i];
        if (commentTrail) {
            if ([line hasSuffix:@" */"]) {
                currentComment = [NSString stringWithFormat:@"%@%@",currentComment,[line substringToIndex:[line length]-3]];
                commentTrail = NO;
            } else if ([line hasSuffix:@"*/"]) {
                currentComment = [NSString stringWithFormat:@"%@%@",currentComment,[line substringToIndex:[line length]-2]];
                commentTrail = NO;
            } else {
                currentComment = [NSString stringWithFormat:@"%@%@\n",currentComment,line];
                commentTrail = YES;
            }
            
        } else if ([line isEqualToString:@"/*"]) {
            currentComment = @"\n";
            commentTrail = YES;
            
        } else if ([line hasPrefix:@"/* "]) {
            commentTrail = ![line hasSuffix:@"*/"];
            if (commentTrail)
                currentComment = [[line substringFromIndex:3] stringByAppendingString:@"\n"];
            else
                currentComment = [line substringWithRange:NSMakeRange(3, [line length]-6)];
            
        } else if ([line hasPrefix:@"\""] && [line hasSuffix:@";"]) {
            NSArray* parts = [line componentsSeparatedByString:@"\" = \""];
            NSAssert([parts count]==2, @"failed to parse string line %d: |%@|",i,line);
            
            NSString* currentKey = [parts[0] substringFromIndex:1];
            NSString* currentValue = [parts[1] substringToIndex:[parts[1] length]-2];
            
//            NSLog(@"key = %@",currentKey);
//            NSLog(@"value = %@",currentValue);
//            NSLog(@"comment = %@",currentComment);
//            NSLog(@"    ");
            
            if (parsedValues[currentKey]) {
                //TODO display these errors
                NSLog(@"!!! duplicate key %@ on row %d. skipping...",currentKey,i);
                currentComment = nil;
                continue;
            }
            
            NSAssert(currentKey!=nil,@"nil key for value %@ on row %d",currentValue,i);
            NSAssert(currentValue!=nil,@"missing value for key %@ on row %d",currentKey,i);
            
            if (currentComment == nil) {
                //TODO display these errors
                NSLog(@"!!! missing comment for key %@ on row %d",currentKey,i);
                currentComment = @"";
            }
            
            [parsedKeys addObject:currentKey];
            parsedValues[currentKey] = currentValue;
            parsedComments[currentKey] = currentComment;
            
            currentComment = nil;
            
        } else if (![line isEqualToString:@""]) {
            NSLog(@"Could not parse line %d: |%@|",i,line);
            NSAssert(NO,@"failed to parse");
        }
    }
    
    self.keys = parsedKeys;
    self.values = parsedValues;
    self.comments = parsedComments;
    
    _parsed = YES;
    _dirty = NO;
}

-(void)saveFile {
    if (!_dirty)
        return;
    
    [self saveFileToURL:_url];
    
    _dirty = NO;
}

-(void)saveFileToURL:(NSURL*)url {
    NSMutableArray* outputParts = [NSMutableArray array];
    
    BOOL first = NO;
    for (NSString* key in [self allKeys]) {
        if (first) {
            [outputParts addObject:@"\n"];
        }
        first = YES;
        [outputParts addObject:@"/* "];
        [outputParts addObject:_comments[key]];
        [outputParts addObject:@" */\n"];
        [outputParts addObject:@"\""];
        [outputParts addObject:key];
        [outputParts addObject:@"\" = \""];
        [outputParts addObject:_values[key]];
        [outputParts addObject:@"\";\n"];
    }
    
    NSString* output = [outputParts componentsJoinedByString:@""];
    [output writeToURL:url atomically:NO encoding:NSUTF16StringEncoding error:nil];
    
    if (url==_url)
        _dirty = NO;
}

#pragma mark - Getters

-(NSArray*)allKeys {
    [self parseFile];
    return self.keys;
}

-(NSString*)valueForKey:(NSString*)key {
    [self parseFile];
    return [self.values objectForKey:key];
}

-(NSString*)commentForKey:(NSString*)key {
    [self parseFile];
    return [self.comments objectForKey:key];
}


#pragma mark - Setters

-(BOOL)ifNeededAddKey:(NSString*)key {
    if (!self.values[key]) {
        [self.keys addObject:key];
        self.values[key] = @"";
        self.comments[key] = @"";
        _dirty = YES;
        return YES;
    }
    return NO;
}

-(void)setValue:(id)value forKey:(NSString *)key {
    [self ifNeededAddKey:key];
    self.values[key] = value;
    _dirty = YES;
}

-(void)setComment:(id)comment forKey:(NSString *)key {
    [self ifNeededAddKey:key];
    self.comments[key] = comment;
    _dirty = YES;
}


#pragma mark - Other mutation

-(void)removeKey:(NSString*)key {
    [self.keys removeObject:key];
    [self.values removeObjectForKey:key];
    [self.comments removeObjectForKey:key];
    _dirty = YES;
}



@end
