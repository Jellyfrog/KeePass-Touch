//
//  WebDAVAddServerViewController.m
//  KeePass Touch
//
//  Created by hwiorn on 2019. 8. 1..
//  Copyright © 2019년 Self. All rights reserved.
//

#import "WebDAVAddServerViewController.h"
#import <LEOWebDAV/LEOWebDAVClient.h>
#import <LEOWebDAV/LEOWebDAVRequest.h>
#import <LEOWebDAV/LEOWebDAVPropertyRequest.h>
#import <LEOWebDAV/LEOWebDAVDownloadRequest.h>
#import "KeychainUtils.h"
#import "KPTextField.h"

@interface WebDAVAddServerViewController () <LEOWebDAVRequestDelegate>
{
    UITextField *_host;
    UITextField *_path;
    UITextField *_username;
    UITextField *_password;
    
}
@end

@implementation WebDAVAddServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    self.title = NSLocalizedString(@"WebDAV Login Data", nil);
    
    _host = [KPTextField new];
    _host.backgroundColor = [UIColor whiteColor];
    _host.placeholder = NSLocalizedString(@"Host", nil);
    [self.view addSubview:_host];
    
    _username = [KPTextField new];
    _username.backgroundColor = [UIColor whiteColor];
    _username.placeholder = NSLocalizedString(@"Username", nil);
    [self.view addSubview:_username];
    
    _password = [KPTextField new];
    _password.backgroundColor = [UIColor whiteColor];
    _password.secureTextEntry = YES;
    _password.placeholder = NSLocalizedString(@"Password", nil);
    [self.view addSubview:_password];
    
    _path = [KPTextField new];
    _path.backgroundColor = [UIColor whiteColor];
    _path.placeholder = NSLocalizedString(@"Remote path", nil);
    [self.view addSubview:_path];
    
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
    
    _host.frame = CGRectMake(edgeSpace, height, self.view.width - edgeSpace * 2, 50);
    height += _host.height + 1;
    
    _username.frame = CGRectMake(edgeSpace, height, self.view.width - edgeSpace * 2, 50);
    height += _username.height + 1;
    
    _password.frame = CGRectMake(edgeSpace, height, self.view.width - edgeSpace * 2, 50);
    height += _password.height + 1;
    
    _path.frame = CGRectMake(edgeSpace, height, self.view.width - edgeSpace * 2, 50);
    height += _path.height + 1;
}

- (void)donePressed {
    // Connect and list contents.
    
    NSString *host = _host.text;
    NSString *path = _path.text;
    
    if(host.length == 0)
        return;
    
    //TODO: HOST https: and http:
    //TODO: port
    
    if(path.length == 0)
        path = @"/";
    
    [self showLoadingAnimation];
    
    NSString *user = _username.text;
    NSString *password = _password.text;
    
    LEOWebDAVClient *client=[[LEOWebDAVClient alloc] initWithRootURL:[NSURL URLWithString:host] andUserName:user andPassword:password];
    
    LEOWebDAVPropertyRequest *request=[[LEOWebDAVPropertyRequest alloc] initWithPath:path];
    [request setDelegate:self];
    [client enqueueRequest:request];
}

- (void)cancelPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissFirstResponder {
    [self.view endEditing:YES];
}

#pragma mark - LEOWebDAV delegate
-(void)request:(LEOWebDAVRequest *)aRequest didFailWithError:(NSError *)error
{
    [self removeLoadingAnimation];
    [self showErrorMessage:NSLocalizedString(@"Error", nil) description:error.localizedDescription];
}

-(void)request:(LEOWebDAVRequest *)aRequest didSucceedWithResult:(id)result
{
    if ([aRequest isKindOfClass:[LEOWebDAVPropertyRequest class]]) {
        NSLog(@"success:%@",result);
    }
    
    [KeychainUtils setString:_host.text forKey:@"kptwebdav_server" andServiceName:@"com.kptouch.webdavaccess"];
    [KeychainUtils setString:_username.text forKey:@"kptwebdav_username" andServiceName:@"com.kptouch.webdavaccess"];
    [KeychainUtils setString:_password.text forKey:@"kptwebdav_password" andServiceName:@"com.kptouch.webdavaccess"];
    [KeychainUtils setString:_path.text forKey:@"kptwebdav_path" andServiceName:@"com.kptouch.webdavaccess"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeLoadingAnimation];
        
#warning rework this, in the future add a completion block
        UIViewController *topVC = [self.navigationController.presentingViewController valueForKey:@"topViewController"];
        if([[[topVC class] description] isEqualToString:@"FilesViewController"])  {
            [topVC performSelector:@selector(showWebDAVOptions) withObject:nil afterDelay:1.5];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
