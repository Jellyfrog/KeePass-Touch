//
//  FTPAddServerViewController.m
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 20.12.17.
//  Copyright © 2017 Self. All rights reserved.
//

#import "FTPAddServerViewController.h"
#import <FTPKit/FTPKit.h>
#import "KeychainUtils.h"
#import "KPTextField.h"

@interface FTPAddServerViewController ()
{
    UITextField *_host;
    UITextField *_port;
    UITextField *_username;
    UITextField *_password;
    
}
@end

@implementation FTPAddServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    self.title = NSLocalizedString(@"FTP Login Data", nil);
    
    _host = [KPTextField new];
    _host.backgroundColor = [UIColor whiteColor];
    
    _host.placeholder = NSLocalizedString(@"Host", nil);
    [self.view addSubview:_host];
    
    _port = [KPTextField new];
    _port.keyboardType = UIKeyboardTypeNumberPad;
    _port.backgroundColor = [UIColor whiteColor];
    _port.placeholder = NSLocalizedString(@"Port", nil);
    
    [self.view addSubview:_port];
    
    _username = [KPTextField new];
    _username.backgroundColor = [UIColor whiteColor];
    _username.placeholder = NSLocalizedString(@"Username", nil);
    [self.view addSubview:_username];
    
    _password = [KPTextField new];
    _password.backgroundColor = [UIColor whiteColor];
    _password.secureTextEntry = YES;
    _password.placeholder = NSLocalizedString(@"Password", nil);
    [self.view addSubview:_password];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(donePressed)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelPressed)];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissFirstResponder)]];
    
    // Do any additional setup after loading the view.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat edgeSpace = [SizeDesign getEdgeSpace];
    
    CGFloat height = [SizeDesign getTopSpace] + NAV_BAR_HEIGHT;
    
    _host.frame = CGRectMake(edgeSpace, height, self.view.width * 3 / 4, 50);
    
    _port.frame = CGRectMake(_host.xOrigin + _host.width + 4, height, self.view.width - _host.width - 4 - edgeSpace * 2, 50);
    height += _host.height + 1;
    
    _username.frame = CGRectMake(edgeSpace, height, self.view.width - edgeSpace * 2, 50);
    height += _username.height + 1;
    
    _password.frame = CGRectMake(edgeSpace, height, self.view.width - edgeSpace * 2, 50);
    height += _password.height + 1;
}

- (void)donePressed {
    // Connect and list contents.
    
    NSString *host = _host.text;
    NSString *port = _port.text;
    
    // intercept illegal values
    if(port.length > 5 || port.intValue == 0 || port.intValue > 65535) {
        [self showErrorMessage:NSLocalizedString(@"Error", nil) description:NSLocalizedString(@"Illegal Port", nil)];
        return;
    }
    
    if(host.length == 0)
        return;
    [self showLoadingAnimation];
    
    NSString *user = _username.text;
    NSString *password = _password.text;
    FTPClient *client = [FTPClient clientWithHost:host port:port.intValue username:user password:password];
    
    [client listContentsAtPath:@"/" showHiddenFiles:NO success:^(NSArray *contents) {
        [KeychainUtils setString:_host.text forKey:@"kptftpserver" andServiceName:@"com.kptouch.ftpaccess"];
        [KeychainUtils setString:_port.text forKey:@"kptftpport" andServiceName:@"com.kptouch.ftpaccess"];
        [KeychainUtils setString:_username.text forKey:@"kptftpusername" andServiceName:@"com.kptouch.ftpaccess"];
        [KeychainUtils setString:_password.text forKey:@"kptftppassword" andServiceName:@"com.kptouch.ftpaccess"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeLoadingAnimation];
            
#warning rework this, in the future add a completion block
            UIViewController *topVC = [self.navigationController.presentingViewController valueForKey:@"topViewController"];
            if([[[topVC class] description] isEqualToString:@"FilesViewController"])  {
                [topVC performSelector:@selector(showFTPOptions) withObject:nil afterDelay:1.5];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        });

    } failure:^(NSError *error) {
        [self removeLoadingAnimation];
        [self showErrorMessage:NSLocalizedString(@"Error", nil) description:error.localizedDescription];
    }];
    
}

- (void)cancelPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissFirstResponder {
    [self.view endEditing:YES];
}

@end
