//
//  WebDAVSelectViewController.h
//  KeePass Touch
//
//  Created by hwiorn on 2019. 8. 1..
//  Copyright © 2019 Self. All rights reserved.
//

#import "KPViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WebDAVSelectViewController : KPViewController

typedef enum {
    WEBDAV_MODE_UPLOAD,
    WEBDAV_MODE_DOWNLOAD
} WebDAV_Mode;

@property (nonatomic, strong) NSArray *filesList;
@property (nonatomic, strong) NSArray *foldersList;
@property (nonatomic, strong) NSString *path;

@property (nonatomic, strong) NSString *loadFilename;


@property (nonatomic) WebDAV_Mode mode;


- (id)initWithMode:(WebDAV_Mode)mode;
- (id)initWithUploadFile:(NSString *)filename;

@end

NS_ASSUME_NONNULL_END
