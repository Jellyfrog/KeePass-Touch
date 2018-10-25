//
//  DropboxManager.m
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 10.06.17.
//  Copyright © 2017 Self. All rights reserved.
//

#import "DropboxManager.h"

#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>


@interface DropboxManager ()

@property (nonatomic, retain) NSArray *kpFiles;
@property (nonatomic, retain) DBUserClient *userClient;

@end


@implementation DropboxManager

+ (DropboxManager *)sharedInstance
{
    static DropboxManager *_sharedInstance;
    
    @synchronized(self) {
        if (_sharedInstance == nil) {
            _sharedInstance = [[DropboxManager alloc] init];
            
        }
    }
    return _sharedInstance;
}

- (void)getAllFilesForClient:(DBUserClient *)client atPath:(NSString *)path {
    self.userClient = client;
    self.kpFiles = [NSArray array];
    
    [[self.userClient.filesRoutes listFolder:path] setResponseBlock:^(DBFILESListFolderResult * _Nullable result, DBFILESListFolderError * _Nullable routeError, DBRequestError * _Nullable networkError) {
        if (result) {
            NSArray<DBFILESMetadata *> *entries = result.entries;
            
            NSString *cursor = result.cursor;
            BOOL hasMore = [result.hasMore boolValue];
            
            for (DBFILESMetadata *entry in entries) {
                if ([entry isKindOfClass:[DBFILESFileMetadata class]]) {
                    DBFILESFileMetadata *fileMetadata = (DBFILESFileMetadata *)entry;
                    if([fileMetadata.name hasSuffix:@"kdb"] || [fileMetadata.name hasSuffix:@"kdbx"])
                        _kpFiles = [_kpFiles arrayByAddingObject:fileMetadata];
                }
            }
            
            if (hasMore)
                [self listFolderContinueWithCursor:cursor];
            else
                [self.delegate didListFolderWithFiles:self.kpFiles];
        }
        else {
            if(networkError) {
                [self.delegate didFailToListFolderWithError:networkError];
            }
            else if(routeError)
                [self.delegate didFailToListFolderWithFolderError:routeError];
        }
     }];
    
    
}

- (void)listFolderContinueWithCursor:(NSString *)cursor {
    [[self.userClient.filesRoutes listFolderContinue:cursor]
     setResponseBlock:^(DBFILESListFolderResult *response, DBFILESListFolderContinueError *routeError,
                        DBRequestError *networkError) {
         if (response) {
             NSArray<DBFILESMetadata *> *entries = response.entries;
             NSString *cursor = response.cursor;
             
             BOOL hasMore = [response.hasMore boolValue];
             
             for (DBFILESMetadata *entry in entries) {
                 if ([entry isKindOfClass:[DBFILESFileMetadata class]]) {
                     DBFILESFileMetadata *fileMetadata = (DBFILESFileMetadata *)entry;
                     if([fileMetadata.name hasSuffix:@"kdb"] || [fileMetadata.name hasSuffix:@"kdbx"])
                        _kpFiles = [_kpFiles arrayByAddingObject:fileMetadata];
                     
                     if (hasMore) {
                         NSLog(@"Folder is large enough where we need to call `listFolderContinue:`");
                         
                         [self listFolderContinueWithCursor:cursor];
                     } else {
                         [self.delegate didListFolderWithFiles:self.kpFiles];
                         NSLog(@"List folder complete.");
                     }
                 }
             }
         }
         else {
             if(networkError) {
                 [self.delegate didFailToListFolderWithError:networkError];
             }
             else if(routeError)
                 [self.delegate didFailToListFolderWithFolderError:routeError];
         }
     }];
}

@end
