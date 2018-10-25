//
//  KPViewController.m
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 20.12.17.
//  Copyright © 2017 Self. All rights reserved.
//

#import "KPViewController.h"
#import "TWMessageBarManager.h"
#import "MBProgressHUD.h"

#define DEFAULT_DURATION_TIME 4.0

@interface KPViewController () <TWMessageBarStyleSheet>
{
    MBProgressHUD *hud;
}
@end

@implementation KPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [TWMessageBarManager sharedInstance].styleSheet = self;
}

#pragma mark - MBProgressHUD

#pragma mark - MBProgressHUD

-(void)showLoadingAnimation
{
    [self showLoadingAnimation:nil subtitle:nil];
}

-(void)showLoadingAnimation:(NSString *)title
{
    [self showLoadingAnimation:title subtitle:nil];
}

-(void)showLoadingAnimation:(NSString *)title subtitle:(NSString *)subtitle
{
    if(hud  == nil)
    {
        if(self.navigationController.view)
        {
            hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        }
        else
        {
            hud = [[MBProgressHUD alloc] initWithView:self.view];
        }
        
    }
    
    if(title != nil){
        hud.label.text = title;
        hud.label.numberOfLines = 0;
        hud.bezelView.color = [UIColor colorWithRed:27/255.0 green:27/255.0 blue:28/255.0 alpha:1];
        hud.label.textColor = [UIColor whiteColor];
        hud.activityIndicatorColor = [UIColor whiteColor];
    }
    else
        if(subtitle != nil)
            hud.detailsLabel.text = subtitle;
    
    hud.square = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addSubview:hud];
        [hud showAnimated:YES];
    });
}

- (void)showLoadingAnimationForMaximumDuration:(NSTimeInterval)seconds {
    if(hud  == nil)
    {
        if(self.navigationController.view)
        {
            hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        }
        else
        {
            hud = [[MBProgressHUD alloc] initWithView:self.view];
        }
        
    }
    hud.square = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addSubview:hud];
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:seconds];
    });
    
}

-(void)removeLoadingAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [hud showAnimated:NO];
        [hud removeFromSuperview];
        hud = nil;
    });
}




#pragma mark - Message Bar

-(void)showErrorMessage:(NSString *)title description:(NSString *)description {
    [self showErrorMessage:title description:description duration:DEFAULT_DURATION_TIME];
}

-(void)showErrorMessage:(NSString *)title description:(NSString *)description duration:(double)duration {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:title description:description type:TWMessageBarMessageTypeError duration:duration statusBarHidden:NO callback:nil];
    });
}

-(void)showSuccessMessage:(NSString *)title description:(NSString *)description
{
    [self showSuccessMessage:title description:description duration:DEFAULT_DURATION_TIME];
}

-(void)showSuccessMessage:(NSString *)title description:(NSString *)description duration:(double)duration
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:title description:description type:TWMessageBarMessageTypeSuccess duration:duration statusBarHidden:NO callback:nil];
    });
}

-(void)showInfoMessage:(NSString *)title description:(NSString *)description
{
    [self showInfoMessage:title description:description duration:DEFAULT_DURATION_TIME];
}

-(void)showInfoMessage:(NSString *)title description:(NSString *)description duration:(double)duration
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:title description:description type:TWMessageBarMessageTypeInfo duration:duration statusBarHidden:NO callback:nil];
    });
}


#pragma mark - TWMessageBarStyleSheet

- (nonnull UIImage *)iconImageForMessageType:(TWMessageBarMessageType)type{
    UIImage *iconImage = nil;
    switch (type)
    {
        case TWMessageBarMessageTypeError:
            iconImage = [UIImage imageNamed:@"icon-error.png"];
            break;
        case TWMessageBarMessageTypeSuccess:
            iconImage = [UIImage imageNamed:@"icon-success.png"];
            break;
        case TWMessageBarMessageTypeInfo:
            iconImage = [UIImage imageNamed:@"icon-info.png"];
            break;
    }
    return iconImage;
}



- (nonnull UIColor *)backgroundColorForMessageType:(TWMessageBarMessageType)type{
    if(type==TWMessageBarMessageTypeSuccess){
        return [UIColor greenColor];
    }
    if(type==TWMessageBarMessageTypeError){
        return [UIColor redColor];
    }
    return [UIColor yellowColor];
}

- (nonnull UIColor *)strokeColorForMessageType:(TWMessageBarMessageType)type {
    return [UIColor clearColor];
}

@end
