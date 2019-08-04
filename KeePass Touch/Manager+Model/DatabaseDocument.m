/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "DatabaseDocument.h"
#import "AppSettings.h"
#import "ImageFactory.h"

@interface DatabaseDocument ()
@property (nonatomic, strong) KdbPassword *kdbPassword;
@end

@implementation DatabaseDocument

- (id)initWithFilename:(NSString *)filename password:(NSString *)password keyFile:(NSString *)keyFile {
    self = [super init];
    if (self) {
        if (password == nil && keyFile == nil) {
            @throw [NSException exceptionWithName:@"IllegalArgument"
                                           reason:NSLocalizedString(@"No password or keyfile specified", nil)
                                         userInfo:nil];
        }
        
        if (filename != nil) {
            NSURL * fileurl = [NSURL URLWithString:filename];
            if([fileurl isFileURL]) {
                filename = [[fileurl.absoluteString
                             stringByRemovingPercentEncoding] substringFromIndex:7];
            }
        }
        self.filename = filename;
        
        if (keyFile != nil) {
            NSURL * keyfileurl = [NSURL URLWithString:keyFile];
            if([keyfileurl isFileURL]) {
                keyFile = [[keyfileurl.absoluteString
                                stringByRemovingPercentEncoding] substringFromIndex:7];
            }
        }

        NSStringEncoding passwordEncoding = [[AppSettings sharedInstance] passwordEncoding];
        self.kdbPassword = [[KdbPassword alloc] initWithPassword:password
                                                passwordEncoding:passwordEncoding
                                                         keyFile:keyFile];

        self.kdbTree = [KdbReaderFactory load:self.filename withPassword:self.kdbPassword];
        
        if([self.kdbTree isKindOfClass:[Kdb4Tree class]])
        {
            [[ImageFactory sharedInstance] initializeWithCustomIcons:((Kdb4Tree *)self.kdbTree).customIcons];
        }
    }
    return self;
}

- (void)save {
    [KdbWriterFactory persist:self.kdbTree file:self.filename withPassword:self.kdbPassword];
}

- (void)logTree {
    NSLog(@"tree is %@",self.kdbTree.root.description);
//    NSMutableArray *array = ((Kdb4Tree *)self.kdbTree).binaries;
    
    for (Kdb4Group *grp in self.kdbTree.root.groups) {
        NSLog(@"group with desc %@", grp.description);
        for(Kdb4Entry *ent in grp.entries)
            NSLog(@"entry with desc %@", ent.description);
        for(Kdb4Group *g in grp.groups)
            NSLog(@"subgrp with desc %@", g.description);
    }
    for(Kdb4Entry *ent in self.kdbTree.root.entries)
        NSLog(@"entry with desc %@", ent.description);
}

+ (void)searchGroup:(KdbGroup *)group searchText:(NSString *)searchText results:(NSMutableArray *)results {
    for (KdbEntry *entry in group.entries) {
        if ([self matchesEntry:entry searchText:searchText]) {
            [results addObject:entry];
        }
    }

    for (KdbGroup *g in group.groups) {
        if (![g.name isEqualToString:@"Backup"] && ![g.name isEqualToString:NSLocalizedString(@"Backup", nil)]) {
            [self searchGroup:g searchText:searchText results:results];
            
        }
    }
}

+ (BOOL)matchesEntry:(KdbEntry *)entry searchText:(NSString *)searchText {
    if ([entry.title rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
        return YES;
    }
    if ([entry.username rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
        return YES;
    }
    if ([entry.url rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
        return YES;
    }
    if ([entry.notes rangeOfString:searchText options:NSCaseInsensitiveSearch].length > 0) {
        return YES;
    }
    return NO;
}

@end
