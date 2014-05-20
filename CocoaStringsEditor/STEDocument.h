//
//  STEDocument.h
//  Strings Editor
//
//  Created by Karl Baron on 2014/05/20.
//  Copyright (c) 2014年 Karl Baron. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "STEStringsFile.h"

@interface STEDocument : NSDocument <NSTableViewDataSource>

@property (nonatomic,weak) IBOutlet NSTableView* tableView;

- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;

@end
