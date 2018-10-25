//
//  DropboxFolderController.m
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 29.07.15.
//  Copyright (c) 2015 Self. All rights reserved.
//

#import "DropboxFolderController.h"
#import "MBProgressHUD.h"

@interface DropboxFolderController ()

@end

@implementation DropboxFolderController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if(self != nil)
    {
        self.path = @"";
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(donePressed:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    return self;
}

- (id)initWithPath:(NSString *)path andStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if(self != nil)
    {
        self.path = path;
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(donePressed:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    return self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.removeFromSuperViewOnHide = YES;
    
    self.folders = [NSArray array];
    self.files = [NSArray array];
    
    self.userClient = [DBClientsManager authorizedClient];
    
    [[self.userClient.filesRoutes listFolder:self.path] setResponseBlock:^(DBFILESListFolderResult * _Nullable result, DBFILESListFolderError * _Nullable routeError, DBRequestError * _Nullable networkError) {
        if (result) {
            NSArray<DBFILESMetadata *> *entries = result.entries;
            
            NSString *cursor = result.cursor;
            BOOL hasMore = [result.hasMore boolValue];
            
            
            [self addEntries:entries];
            
            if (hasMore) {
                [self listFolderContinueWithCursor:cursor];
            } else {
                NSLog(@"List folder complete.");
                if(self.folders.count == 0 && self.files.count == 0)
                {
                    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
                    hud.mode = MBProgressHUDModeText;
                    hud.label.text = NSLocalizedString(@"No Folders or Files in here", nil);
                }
                else
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                NSSortDescriptor *sortDescriptor;
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                             ascending:YES selector:@selector(caseInsensitiveCompare:)];
                
                self.folders = [self.folders sortedArrayUsingDescriptors:@[sortDescriptor]];
                self.files = [self.files sortedArrayUsingDescriptors:@[sortDescriptor]];
                [self.tableView reloadData];
            }
        } else {
            NSLog(@"%@\n%@\n", routeError, networkError);
        }
    }];
}


#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.folders.count + self.files.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"UITableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }
    
    if(indexPath.row < self.folders.count)
    {
        cell.textLabel.text = [self.folders objectAtIndex:indexPath.row].name;
        cell.imageView.image = [UIImage imageNamed:@"folder-icon"];
    }
    else if(indexPath.row < (self.files.count + self.folders.count))
    {
        cell.textLabel.text = [self.files objectAtIndex:(indexPath.row - self.folders.count)].name;
        cell.imageView.image = [UIImage imageNamed:@"file"];
    }
    
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row < self.folders.count)
    {
        if(self.path.length == 0)
            self.path = @"/";
        NSString *newPath = [[self.path stringByAppendingString:[tableView cellForRowAtIndexPath:indexPath].textLabel.text] stringByAppendingString:@"/"];
        DropboxFolderController *dfc = [[DropboxFolderController alloc] initWithPath:newPath andStyle:self.tableView.style];
        [self.navigationController pushViewController:dfc animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Dropbox Handling

- (void)listFolderContinueWithCursor:(NSString *)cursor {
    [[self.userClient.filesRoutes listFolderContinue:cursor]
     setResponseBlock:^(DBFILESListFolderResult *response, DBFILESListFolderContinueError *routeError,
                        DBRequestError *networkError) {
         if (response) {
             NSArray<DBFILESMetadata *> *entries = response.entries;
             NSString *cursor = response.cursor;
             BOOL hasMore = [response.hasMore boolValue];
             
             [self addEntries:entries];
             
             if (hasMore) {
                 [self listFolderContinueWithCursor:cursor];
             } else {
                 NSLog(@"List folder complete.");
                 if(self.folders.count == 0 && self.files.count == 0)
                 {
                     MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
                     hud.mode = MBProgressHUDModeText;
                     hud.label.text = NSLocalizedString(@"No Folders or Files in here", nil);
                 }
                 else
                     [MBProgressHUD hideHUDForView:self.view animated:YES];
                 NSSortDescriptor *sortDescriptor;
                 sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                              ascending:YES selector:@selector(caseInsensitiveCompare:)];
                 
                 self.folders = [self.folders sortedArrayUsingDescriptors:@[sortDescriptor]];
                 self.files = [self.files sortedArrayUsingDescriptors:@[sortDescriptor]];
                 [self.tableView reloadData];
             }
         } else {
             NSLog(@"%@\n%@\n", routeError, networkError);
         }
     }];
}

- (void)addEntries:(NSArray <DBFILESMetadata *> *)entries {
    for (DBFILESMetadata *entry in entries) {
        if ([entry isKindOfClass:[DBFILESFileMetadata class]]) {
            DBFILESFileMetadata *fileMetadata = (DBFILESFileMetadata *)entry;
            if([fileMetadata.name hasSuffix:@"kdb"] || [fileMetadata.name hasSuffix:@"kdbx"])
                self.files = [self.files arrayByAddingObject:fileMetadata];
        } else if ([entry isKindOfClass:[DBFILESFolderMetadata class]]) {
            DBFILESFolderMetadata *folderMetadata = (DBFILESFolderMetadata *)entry;
            self.folders = [self.folders arrayByAddingObject:folderMetadata];
        }
//        else if ([entry isKindOfClass:[DBFILESDeletedMetadata class]]) {
//            // ignore
//        }
    }
}

#pragma mark - IBActions

- (IBAction)cancelPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)donePressed:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.path forKey:@"DropboxPath"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DROPBOX_SYNC_NOTIFICATION" object:nil];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
