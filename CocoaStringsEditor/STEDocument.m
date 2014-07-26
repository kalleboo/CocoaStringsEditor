//
//  STEDocument.m
//  Strings Editor
//
//  Created by Karl Baron on 2014/05/20.
//  Copyright (c) 2014年 Karl Baron. All rights reserved.
//

#import "STEDocument.h"

@interface STEDocument ()

@property (nonatomic,strong) NSString* defaultStringsLanguage;
@property (nonatomic,strong) NSDictionary* stringsFiles;

@end

@implementation STEDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"STEDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.

    NSLog(@"windowControllerDidLoadNib start");

    NSTableColumn* column;
    
    column = [[NSTableColumn alloc] initWithIdentifier:@"keyColumn"];
    [column.headerCell setStringValue:@"Key"];
    [column setEditable:NO];
    [self.tableView addTableColumn:column];
    
    column = [[NSTableColumn alloc] initWithIdentifier:@"commentColumn"];
    [column.headerCell setStringValue:@"Comment"];
    [column setEditable:NO];
    [self.tableView addTableColumn:column];
    
    column = [[NSTableColumn alloc] initWithIdentifier:self.defaultStringsLanguage];
    [column.headerCell setStringValue:self.defaultStringsLanguage];
    [self.tableView addTableColumn:column];

    for (NSString* key in self.stringsFiles) {
        if ([self.defaultStringsLanguage isEqualToString:key])
            continue;
        
        NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:key];
        [column.headerCell setStringValue:key];
        [self.tableView addTableColumn:column];
    }

    NSLog(@"windowControllerDidLoadNib done");
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

#pragma mark - NSDocument read/write

-(BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    
    NSLog(@"readFromURL start");
    
    STEStringsFile* loadFile;
    
    NSMutableDictionary* loadedStringsFiles = [NSMutableDictionary dictionary];
    
    loadFile = [[STEStringsFile alloc] initWithURL:url];
    loadedStringsFiles[loadFile.language] = loadFile;
    self.defaultStringsLanguage = loadFile.language;
    
    NSString* searchFileName = [url lastPathComponent];
    NSURL* parentDir = [[url URLByDeletingLastPathComponent] URLByDeletingLastPathComponent];
    
    NSArray* dirListing = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:parentDir
                                                        includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                                           options:0
                                                                             error:nil];
    for (NSURL* item in dirListing) {
        if (loadedStringsFiles[item.lastPathComponent]) {
            continue;
        }
        
        NSNumber *isDirectory = nil;
        [item getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        if (![item.pathExtension isEqualToString:@"lproj"] || ![isDirectory boolValue])
            continue;
        
        NSURL* searchChild = [item URLByAppendingPathComponent:searchFileName];
        if ([searchChild checkResourceIsReachableAndReturnError:nil]) {
            loadFile = [[STEStringsFile alloc] initWithURL:searchChild];
            loadedStringsFiles[loadFile.language] = loadFile;
        }
    }
    
    self.stringsFiles = loadedStringsFiles;
    
    NSLog(@"readFromURL done");
    [self.tableView reloadData];
    
    return YES;
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    [self.stringsFiles[self.defaultStringsLanguage] saveFileToURL:url];
    
    for (NSString* key in self.stringsFiles) {
        if ([self.defaultStringsLanguage isEqualToString:key])
            continue;
        
        [self.stringsFiles[key] saveFile];
    }

    return YES;
}

-(BOOL) isEntireFileLoaded {
    return ((STEStringsFile*)self.stringsFiles[self.defaultStringsLanguage]).parsed;
}

#pragma mark - Copy/Paste

-(IBAction)cut:(id)sender {
    [self copy:sender];

    if ([self.tableView selectedRow]>-1) {
        NSMutableArray* keysToDelete = [NSMutableArray array];
        
        [[self.tableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [keysToDelete addObject:[self allKeys][idx]];
        }];
        
        for (NSString* key in keysToDelete) {
            for (NSString* lang in self.stringsFiles) {
                STEStringsFile* file = self.stringsFiles[lang];
                [file removeKey:key];
            }
        }

        [self.tableView reloadData];
    }
}

- (IBAction)copy:(id)sender {
    if ([self.tableView selectedRow]>-1) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        
        NSMutableArray* copiedRows = [NSMutableArray array];

        [[self.tableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            NSMutableDictionary* row = [NSMutableDictionary dictionary];
            NSString* key = [self allKeys][idx];
            row[@"key"] = key;
            row[@"comment"] = [self.stringsFiles[self.defaultStringsLanguage] commentForKey:key];
            for (NSString* lang in self.stringsFiles) {
                NSString* value = [self.stringsFiles[lang] valueForKey:key];
                if (value)  //skip missing languages
                    row[lang] = value;
            }
            [copiedRows addObject:row];
        }];
        
        NSString* json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:copiedRows options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
        [pasteboard writeObjects:@[json]];
    }
}

- (IBAction)paste:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classes = [[NSArray alloc] initWithObjects:[NSString class], nil];
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
    NSString* copiedItem = copiedItems[0];
    
    NSArray* rowsToPaste = [NSJSONSerialization JSONObjectWithData:[copiedItem dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    if (!rowsToPaste) {
        NSBeep();
        return;
    }
    
    NSLog(@"pasting %@",rowsToPaste);
    for (NSMutableDictionary* row in rowsToPaste) {
        NSString* key = row[@"key"];
        NSString* comment = row[@"comment"];

        if (!key || !comment) {
            NSBeep();
            return;
        }
        
        for (NSString* lang in self.stringsFiles) {
            if (!row[lang]) //skip missing languages
                continue;
            
            STEStringsFile* file = self.stringsFiles[lang];
            [file setValue:row[lang] forKey:key];
            [file setComment:comment forKey:key];
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - NSTableViewDataSource

-(NSArray*)allKeys {
    return [self.stringsFiles[self.defaultStringsLanguage] allKeys];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[self allKeys] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"commentColumn"]) {
        return [self.stringsFiles[self.defaultStringsLanguage] commentForKey:[self allKeys][rowIndex]];
    
    } else if ([[aTableColumn identifier] isEqualToString:@"keyColumn"]) {
        return [self allKeys][rowIndex];

    } else {
        return [self.stringsFiles[[aTableColumn identifier]] valueForKey:[self allKeys][rowIndex]];
    }
    
    return @"???";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"commentColumn"]) {
        //not editable. if we make it editable, have to loop through all strings files
    } else if ([[aTableColumn identifier] isEqualToString:@"keyColumn"]) {
        //not editable. if we make it editable, have to loop through all strings files
    } else {
        [self.stringsFiles[[aTableColumn identifier]] setValue:anObject forKey:[self allKeys][rowIndex]];
    }
}

@end
