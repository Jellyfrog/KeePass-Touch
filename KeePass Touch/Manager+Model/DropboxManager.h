//
//  DropboxManager.h
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 10.06.17.
//  Copyright © 2017 Self. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBUserClient, DBRequestError, DBFILESFileMetadata, DBFILESListFolderError;

@protocol DropboxManagerDelegate <NSObject>

- (void)didListFolderWithFiles:(NSArray <DBFILESFileMetadata *> *)keepassFiles;
- (void)didFailToListFolderWithError:(DBRequestError *)error;
- (void)didFailToListFolderWithFolderError:(NSObject *)error;

@end

@interface DropboxManager : NSObject

@property (nonatomic, retain) id<DropboxManagerDelegate> delegate;


+ (DropboxManager *)sharedInstance;
- (void)getAllFilesForClient:(DBUserClient *)client atPath:(NSString *)path;

@end
