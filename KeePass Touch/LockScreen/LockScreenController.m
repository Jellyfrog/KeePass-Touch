/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import "KeePassTouchAppDelegate.h"
#import "KeychainUtils.h"
#import "LockScreenController.h"
#import "AppSettings.h"

#define DURATION 0.3

@interface LockScreenController ()

@property (nonatomic, retain) PinViewController *pinViewController;
@property (nonatomic, retain) UIViewController *previousViewController;

@end

@implementation LockScreenController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _pinViewController = [[PinViewController alloc] init];
        _pinViewController.delegate = self;

        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
        imageView.image = [[UIImage imageNamed:@"stretchme-7"] resizableImageWithCapInsets:UIEdgeInsetsMake(65, 0, 45, 0)];
        self.view = imageView;

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(applicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate {
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad || [UIDevice currentDevice].orientation == UIDeviceOrientationPortrait;
}

- (UIViewController *)topViewController {
    KeePassTouchAppDelegate *appDelegate = [KeePassTouchAppDelegate appDelegate];
    UIViewController *frontViewController = appDelegate.window.rootViewController;
    while (frontViewController.presentedViewController != nil) {
        frontViewController = frontViewController.presentedViewController;
    }
    return frontViewController;
}

- (void)show {
    self.previousViewController = [self topViewController];
    [self.previousViewController presentViewController:self animated:NO completion:nil];
}

+ (void)present {
    LockScreenController *lockScreenController = [[LockScreenController alloc] init];
    NSLog(@"presenting lockscreen");
    [lockScreenController show];
}

- (void)hide {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)lock {
    KeePassTouchAppDelegate *appDelegate = [KeePassTouchAppDelegate appDelegate];
//    AppSettings *appSettings = [AppSettings sharedInstance];
    if (!appDelegate.locked) {
//        if([appSettings isTouchIDEnabled]) {
//            self.pinViewController.textLabel.text = NSLocalizedString(@"Enter TouchID", nil);
//            [self presentViewController:self.pinViewController animated:NO completion:nil];
//        }
//        else
//        {
        if(!self.pinViewController.beingPresented) {
            self.pinViewController.textLabel.text = NSLocalizedString(@"Enter your PIN to unlock", nil);
            [self presentViewController:self.pinViewController animated:NO completion:nil];
        }
        
//        }
        
    }
}

- (void)unlock {
    KeePassTouchAppDelegate *appDelegate = [KeePassTouchAppDelegate appDelegate];
    appDelegate.locked = NO;

    [self.previousViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)pinViewControllerDidShow:(PinViewController *)controller {
    KeePassTouchAppDelegate *appDelegate = [KeePassTouchAppDelegate appDelegate];
    appDelegate.locked = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Get the time when the application last exited
    AppSettings *appSettings = [AppSettings sharedInstance];
    NSDate *exitTime = [appSettings exitTime];
    
    // Check if the PIN is enabled
    if ( /*( [appSettings isTouchIDEnabled] || [appSettings pinEnabled]  )*/ [appSettings pinEnabled] && exitTime != nil) {
        // Check if it's been longer then lock timeout
        NSTimeInterval timeInterval = -[exitTime timeIntervalSinceNow];
        if (timeInterval > [appSettings pinLockTimeout]) {
            [self lock];
        } else {
            [self hide];
        }
    } else {
        [self hide];
    }
}

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {
    NSString *validPin = [KeychainUtils stringForKey:@"PIN" andServiceName:@"com.kptouch.pin"];
    if (validPin == nil) {
        // Delete keychain data
        KeePassTouchAppDelegate *appDelegate = [KeePassTouchAppDelegate appDelegate];
        [appDelegate deleteKeychainData];
        
        // Hide spashscreen
        [self unlock];
    } else {
        AppSettings *appSettings = [AppSettings sharedInstance];
        
        // Check if the PIN is valid
        if ([pin isEqualToString:validPin]) {
            // Reset the number of pin failed attempts
            [appSettings setPinFailedAttempts:0];
            
            // Dismiss the pin view
            [self unlock];
        } else {
            // Vibrate to signify they are a bad user
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            [controller clearEntry];
            
            if (![appSettings deleteOnFailureEnabled]) {
                // Update the status message on the PIN view
                controller.textLabel.text = NSLocalizedString(@"Incorrect PIN", nil);
            } else {
                // Get the number of failed attempts
                NSInteger pinFailedAttempts = [appSettings pinFailedAttempts];
                [appSettings setPinFailedAttempts:++pinFailedAttempts];

                // Get the number of failed attempts before deleting
                NSInteger deleteOnFailureAttempts = [appSettings deleteOnFailureAttempts];
                
                // Update the status message on the PIN view
                NSInteger remainingAttempts = (deleteOnFailureAttempts - pinFailedAttempts);

                // Update the incorrect pin message
                if (remainingAttempts > 0) {
                    controller.textLabel.text = [NSString stringWithFormat:@"%@\n%@: %ld", NSLocalizedString(@"Incorrect PIN", nil), NSLocalizedString(@"Attempts Remaining", nil), (long)remainingAttempts];
                } else {
                    controller.textLabel.text = NSLocalizedString(@"Incorrect PIN", nil);
                }
                
                // Check if they have failed too many times
                if (pinFailedAttempts >= deleteOnFailureAttempts) {
                    // Delete all data
                    KeePassTouchAppDelegate *appDelegate = [KeePassTouchAppDelegate appDelegate];
                    [appDelegate deleteAllData];
                    
                    // Dismiss the pin view
                    [self unlock];
                }
            }
        }
    }
}
//
//-(void)pinViewController:(PinViewController *)controller touchIDEntered:(BOOL)success {
//    if(success) {
//        [self unlock];
//    }
//    else {
//        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//    }
//    
//    
//}

@end
