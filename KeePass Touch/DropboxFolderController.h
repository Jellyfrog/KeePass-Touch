//
//  DropboxFolderController.h
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 29.07.15.
//  Copyright (c) 2015 Self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

@interface DropboxFolderController : UITableViewController

@property (nonatomic, assign) id target;


@property (nonatomic, strong) DBUserClient *userClient;
@property (nonatomic, strong) NSArray <DBFILESFolderMetadata *> *folders;
@property (nonatomic, strong) NSArray <DBFILESFileMetadata *> *files;

@property (nonatomic, strong) NSString *path;

@end
