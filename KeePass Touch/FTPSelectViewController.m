//
//  FTPSelectViewController.m
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 29.01.15.
//  Copyright (c) 2015 Self. All rights reserved.
//

#import "FTPSelectViewController.h"
#import "FilesViewController.h"
#import "KeePassTouchAppDelegate.h"
#import "MBProgressHUD.h"
#import "KeychainUtils.h"
#import <FTPKit/FTPKit.h>

@interface FTPSelectViewController () <UITableViewDataSource, UITableViewDelegate>

enum {
    SECTION_FOLDERS,
    SECTION_FILES
};

@property (nonatomic, retain) FTPClient *client;
@property (nonatomic, retain) UITableView *tableView;

@end

@implementation FTPSelectViewController

@synthesize tableView;
@synthesize client;

- (id)init {
    self = [super init];
    if(self) {
        
        NSString *server = [KeychainUtils stringForKey:@"kptftpserver" andServiceName:@"com.kptouch.ftpaccess"];
        NSString *port = [KeychainUtils stringForKey:@"kptftpport" andServiceName:@"com.kptouch.ftpaccess"];
        NSString *user = [KeychainUtils stringForKey:@"kptftpusername" andServiceName:@"com.kptouch.ftpaccess"];
        NSString *pw = [KeychainUtils stringForKey:@"kptftppassword" andServiceName:@"com.kptouch.ftpaccess"];
        
        self.client = [FTPClient clientWithHost:server port:port.intValue username:user password:pw];
    }
    return self;
}

- (id)initWithMode:(FTP_Mode)mode {
    self = [self init];
    if(self) {
        self.mode = mode;
        
        if(mode == FTP_MODE_UPLOAD)
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(backPressed)];
        self.filesList = [NSArray array];
        self.foldersList = [NSArray array];
        
    }
    return self;
}

- (id)initWithUploadFile:(NSString *)filename {
    self = [self init];
    if(self) {
        self.mode = FTP_MODE_UPLOAD;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(backPressed)];
        self.filesList = [NSArray array];
        self.foldersList = [NSArray array];
        self.loadFilename = filename;
    }
    return self;
}

- (id)initWithoutCancelWithMode:(FTP_Mode)mode andClient:(FTPClient *)client {
    self = [super init];
    if(self) {
        self.client = client;
        self.mode = mode;
        if(mode == FTP_MODE_UPLOAD)
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)];
        self.filesList = [NSArray array];
        self.foldersList = [NSArray array];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do setup here
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view = self.tableView;
    
    [self showLoadingAnimation];
    
    [client listContentsAtPath:self.path showHiddenFiles:NO success:^(NSArray *contents) {
        
        for (FTPHandle *handle in contents) {
            if (handle.type == FTPHandleTypeFile) {
                if([handle.name containsString:@".kdb"] || [handle.name containsString:@".key"])
                    self.filesList = [self.filesList arrayByAddingObject:handle.name];
            } else if (handle.type == FTPHandleTypeDirectory) {
                self.foldersList = [self.foldersList arrayByAddingObject:handle.name];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self removeLoadingAnimation];
        });
    } failure:^(NSError *error) {
        [self removeLoadingAnimation];
        [self showErrorMessage:NSLocalizedString(@"Error", nil) description:error.localizedDescription];
    }];
}

- (void)donePressed {
    NSLog(@"Folder for Upload %@", self.path);
    
    BOOL found = NO;
    
    for (NSString *aFilename in self.filesList) {
        if ([self.loadFilename compare:aFilename] == NSOrderedSame && self.loadFilename.length == aFilename.length) {
            NSLog(@"File exists ");
            found = YES;
        }
    }
    if(found)
    {
        UIAlertController *alertCon = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Overwrite", nil) message:NSLocalizedString(@"File with filename already exists. Should overwrite existing file?", nil) preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *uploadAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self startUpload];
        }];
        
        [alertCon addAction:uploadAction];
        [alertCon addAction:cancelAction];
        
        [self presentViewController:alertCon animated:YES completion:nil];
        
    }
    else
    {
        [self startUpload];
    }
    
}

- (void)backPressed {
    if(self == [self.navigationController.viewControllers objectAtIndex:0])
    {
        [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
    else
        NSLog(@"Apparently didn't work on top so don't go back");
}

- (void)startDownload {
    
    [self showLoadingAnimation:NSLocalizedString(@"Downloading...", nil)];
    
    NSString *documentsDirectory = [KeePassTouchAppDelegate documentsDirectory];
    NSString *localPath = [documentsDirectory stringByAppendingPathComponent:self.loadFilename];
    
    [self.client downloadFile:[self.path stringByAppendingPathComponent:self.loadFilename] to:localPath progress:nil success:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeLoadingAnimation];
            [self dismissViewControllerAnimated:YES completion:nil];
        });
        
    } failure:^(NSError *error) {
        [self removeLoadingAnimation];
        [self showErrorMessage:NSLocalizedString(@"Error", nil) description:error.localizedDescription];
    }];
}

- (void)startUpload {
    
    // Info Box
    [self showLoadingAnimation:NSLocalizedString(@"Uploading...", nil)];
    
    // Get the document's directory
    
    NSString *documentsDirectory = [KeePassTouchAppDelegate documentsDirectory];
    
    NSString *localPath = [documentsDirectory stringByAppendingPathComponent:self.loadFilename];
    NSString *uploadPath = [self.path stringByAppendingPathComponent:self.loadFilename];
    
    
    [self.client uploadFile:localPath to:uploadPath progress:nil success:^{
        [self removeLoadingAnimation];
        [self dismissViewControllerAnimated:YES completion:nil];
    } failure:^(NSError *error) {
        [self removeLoadingAnimation];
        [self showErrorMessage:NSLocalizedString(@"Error", nil) description:error.localizedDescription];
    }];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case SECTION_FOLDERS:
            return self.foldersList.count;
            break;
        case SECTION_FILES:
            return self.filesList.count;
            break;
        default:
            return 0;
            break;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FTPEntry";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        if(indexPath.section == SECTION_FOLDERS)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.accessoryView.tintColor = [UIColor blueColor];
        }
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.tintColor = [UIColor blueColor];
    }
    
    // Configure the cell
    switch (indexPath.section) {
        case SECTION_FOLDERS:
        {
            NSString *currentText = [self.foldersList objectAtIndex:indexPath.row];
            cell.textLabel.text = currentText;
            cell.imageView.image = [UIImage imageNamed:@"folder-icon"];
        }
            break;
        case SECTION_FILES:
        {
            NSString *currentText = [self.filesList objectAtIndex:indexPath.row];
            cell.textLabel.text = currentText;
            cell.imageView.image = [UIImage imageNamed:@"file"];
        }
            break;
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case SECTION_FOLDERS:
        {
            FTPSelectViewController *next = [[FTPSelectViewController alloc] initWithoutCancelWithMode:self.mode andClient:self.client];
            next.loadFilename = self.loadFilename;
            next.path = [self.path stringByAppendingPathComponent:[tableView cellForRowAtIndexPath:indexPath].textLabel.text];
            [self.navigationController pushViewController:next animated:YES];
        }
            break;
        case SECTION_FILES:
        {
            if(self.mode == FTP_MODE_DOWNLOAD)
            {
                self.loadFilename = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
                
                NSString *documentsDirectory = [KeePassTouchAppDelegate documentsDirectory];
                NSString *localPath = [documentsDirectory stringByAppendingPathComponent:self.loadFilename];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:localPath])
                {
                    UIAlertController *alertCon = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Overwrite", nil) message:NSLocalizedString(@"File with filename already exists. Should overwrite existing file?", nil) preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:UIAlertActionStyleCancel handler:nil];
                    UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self startDownload];
                    }];
                    
                    [alertCon addAction:cancelAction];
                    [alertCon addAction:downloadAction];
                    [self presentViewController:alertCon animated:YES completion:nil];
                }
                else
                {
                    [self startDownload];
                }
            }
        }
            break;
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
