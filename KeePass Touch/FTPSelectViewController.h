//
//  FTPSelectViewController.h
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 29.01.15.
//  Copyright (c) 2015 Self. All rights reserved.
//

#import "KPViewController.h"

@interface FTPSelectViewController : KPViewController

typedef enum {
    FTP_MODE_UPLOAD,
    FTP_MODE_DOWNLOAD
} FTP_Mode;

@property (nonatomic, strong) NSArray *filesList;
@property (nonatomic, strong) NSArray *foldersList;
@property (nonatomic, strong) NSString *path;

@property (nonatomic, strong) NSString *loadFilename;


@property (nonatomic) FTP_Mode mode;


- (id)initWithMode:(FTP_Mode)mode;
- (id)initWithUploadFile:(NSString *)filename;

@end
