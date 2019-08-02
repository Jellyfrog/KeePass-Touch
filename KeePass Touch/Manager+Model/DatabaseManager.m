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

#import "DatabaseManager.h"
#import "KeePassTouchAppDelegate.h"
#import "KeychainUtils.h"
#import "PasswordViewController.h"
#import "AppSettings.h"
#import "ImageFactory.h"
#import <LocalAuthentication/LocalAuthentication.h>

@implementation DatabaseManager

static DatabaseManager *sharedInstance;

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized)     {
        initialized = YES;
        sharedInstance = [[DatabaseManager alloc] init];
    }
}

+ (DatabaseManager*)sharedInstance {
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if(self)
    {
        self.spinnerView = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 25,
                                                                                    [UIScreen mainScreen].bounds.size.height / 2 - 25,
                                                                                    50,
                                                                                    50)];
        self.spinnerView.color = [UIColor blueColor];
        self.spinnerView.tag = 1007;
        
        [[KeePassTouchAppDelegate appDelegate].navigationController.view addSubview:self.spinnerView];
    }
    return self;
}

- (void)openDatabaseDocument:(NSString*)filename animated:(BOOL)animated {
    __block BOOL databaseLoaded = NO;
    [[ImageFactory sharedInstance] clear];
    self.selectedFilename = filename;
    
    // Get the application delegate
    KeePassTouchAppDelegate *appDelegate = [KeePassTouchAppDelegate appDelegate];
    
    // Get the documents directory
    NSString *documentsDirectory = [KeePassTouchAppDelegate documentsDirectory];
    
    // Load the password and keyfile from the keychain
    NSString *password = [KeychainUtils stringForKey:self.selectedFilename
                                      andServiceName:@"com.kptouch.passwords"];
    __block NSString *keyFile = [KeychainUtils stringForKey:self.selectedFilename
                                     andServiceName:@"com.kptouch.keyfiles"];
    // Try and load the database with the cached password from the keychain
    if (password != nil || keyFile != nil) {
        if ([[AppSettings sharedInstance] isTouchIDEnabled])
        {
            LAContext *context = [[LAContext alloc] init];
            databaseLoaded = YES;
            // Authenticate User
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                    localizedReason:NSLocalizedString(@"Decrypt Database", nil)
                              reply:^(BOOL success, NSError *error) {
                                  if(error)
                                  {
                                      if(error.code == LAErrorUserFallback)
                                      {
                                          // Fallback
                                          // LIKE NOT LOADED
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              PasswordViewController *passwordViewController = [[PasswordViewController alloc] initWithFilename:filename];
                                              passwordViewController.donePressed = ^(FormViewController *formViewController) {
                                                  [self openDatabaseWithPasswordViewController:(PasswordViewController *)formViewController];
                                              };
                                              passwordViewController.cancelPressed = ^(FormViewController *formViewController) {
                                                  [formViewController dismissViewControllerAnimated:YES completion:nil];
                                              };
                                              
                                              // Create a default keyfile name from the database name
                                              keyFile = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"key"];
                                              
                                              // Select the keyfile if it's in the list
                                              NSInteger index = [passwordViewController.keyFileCell.choices indexOfObject:keyFile];
                                              if (index != NSNotFound) {
                                                  passwordViewController.keyFileCell.selectedIndex = index;
                                              } else {
                                                  passwordViewController.keyFileCell.selectedIndex = 0;
                                              }
                                              
                                              UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:passwordViewController];
                                              [appDelegate.window.rootViewController presentViewController:navigationController animated:animated completion:nil];
                                          });
                                          
                                          
                                      }
                                      else if(error.code != LAErrorUserCancel) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                              NSLog(@"Error in Touch ID %@", [error description]);
                                              [errorView show];
                                              return;
                                              
                                          });
                                      }
                                  }
                                  else {
                                      if(success)
                                      {
                                          [self performSelectorOnMainThread:@selector(startSpinner) withObject:nil waitUntilDone:YES];
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              // write all your code here
                                              
                                              // Get the absolute path to the database
                                              NSString *path = [documentsDirectory stringByAppendingPathComponent:self.selectedFilename];
                                              NSURL * fileurl = [NSURL URLWithString:self.selectedFilename];
                                              if([fileurl isFileURL])
                                                  path = fileurl.absoluteString;
                                              
                                              // Get the absolute path to the keyfile
                                              NSString *keyFilePath = nil;
                                              if (keyFile != nil) {
                                                  NSURL * keyfileurl = [NSURL URLWithString:keyFile];
                                                  if([keyfileurl isFileURL]) {
                                                      keyFilePath = [[keyfileurl.absoluteString
                                                                  stringByRemovingPercentEncoding] substringFromIndex:7];
                                                  } else {
                                                      keyFilePath = [documentsDirectory stringByAppendingPathComponent:keyFile];
                                                  }
                                              }
                                              
                                              @try {
                                                  DatabaseDocument *dd = [[DatabaseDocument alloc] initWithFilename:path password:password keyFile:keyFilePath];
                                                  
                                                  // Set the database document in the application delegate
                                                  appDelegate.databaseDocument = dd;
                                              } @catch (NSException *exception) {
                                                  // Ignore
                                                  NSLog(@"Exception Database Manager: %@", exception);
                                                  [self.spinnerView removeFromSuperview];
                                              }
                                          });
                                          
                                      }
                                      else
                                      {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              UIAlertView *wrongID = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unknown Touch ID", nil) message:NSLocalizedString(@"Unknown Touch ID entered. Please try again.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                              NSLog(@"Wrong Touch ID");
                                              [wrongID show];
                                          });
                                          
                                      }
                                  }
                                  
                              }
             ];
        }
        else {
            // Get the absolute path to the database
            NSString *path = [documentsDirectory stringByAppendingPathComponent:self.selectedFilename];
            NSURL * fileurl = [NSURL URLWithString:self.selectedFilename];
            if([fileurl isFileURL])
                path = fileurl.absoluteString;
            
            // Get the absolute path to the keyfile
            NSString *keyFilePath = nil;
            if (keyFile != nil) {
                keyFilePath = [documentsDirectory stringByAppendingPathComponent:keyFile];
            }
            [self performSelectorOnMainThread:@selector(startSpinner) withObject:nil waitUntilDone:YES];
            // Load the database
            @try {
                
                
                DatabaseDocument *dd = [[DatabaseDocument alloc] initWithFilename:path password:password keyFile:keyFilePath];
                
                databaseLoaded = YES;
                
                // Set the database document in the application delegate
                appDelegate.databaseDocument = dd;
            } @catch (NSException *exception) {
                // Ignore
                [self.spinnerView removeFromSuperview];
            }
        }
    }
    
    // Prompt the user for the password if we haven't loaded the database yet
    if (!databaseLoaded) {
        // Prompt the user for a password
        PasswordViewController *passwordViewController = [[PasswordViewController alloc] initWithFilename:filename];
        passwordViewController.donePressed = ^(FormViewController *formViewController) {
            [self openDatabaseWithPasswordViewController:(PasswordViewController *)formViewController];
        };
        passwordViewController.cancelPressed = ^(FormViewController *formViewController) {
            [formViewController dismissViewControllerAnimated:YES completion:nil];
        };
        
        // Create a default keyfile name from the database name
        NSURL * filename_url = [NSURL URLWithString:filename];
        if([filename_url isFileURL]) {
            filename = [[[[filename_url.absoluteString
                         stringByRemovingPercentEncoding] substringFromIndex:7]  stringByDeletingPathExtension] stringByAppendingPathExtension:@"key"];
            keyFile = [[NSURL fileURLWithPath:filename] absoluteString];
        } else {
            keyFile = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"key"];
        }
        
        // Select the keyfile if it's in the list
        NSInteger index = [passwordViewController.keyFileCell.choices indexOfObject:keyFile];
        if (index != NSNotFound) {
            passwordViewController.keyFileCell.selectedIndex = index;
        } else {
            passwordViewController.keyFileCell.selectedIndex = 0;
        }
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:passwordViewController];
        
        [appDelegate.window.rootViewController presentViewController:navigationController animated:animated completion:nil];
    }
}

- (void)openDatabaseWithPasswordViewController:(PasswordViewController *)passwordViewController {
    NSString *documentsDirectory = [KeePassTouchAppDelegate documentsDirectory];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:self.selectedFilename];
    NSURL * fileurl = [NSURL URLWithString:self.selectedFilename];
    if([fileurl isFileURL])
        path = [[fileurl.absoluteString
                 stringByRemovingPercentEncoding] substringFromIndex:7];

    // Get the password
    NSString *password = passwordViewController.masterPasswordFieldCell.textField.text;
    if ([password isEqualToString:@""]) {
        password = nil;
    }

    // Get the keyfile
    NSString *keyFile = [passwordViewController.keyFileCell getSelectedItem];
    if ([keyFile isEqualToString:NSLocalizedString(@"None", nil)]) {
        keyFile = nil;
    }

    // Get the absolute path to the keyfile
    NSString *keyFilePath = nil;
    if (keyFile != nil) {
        NSURL * keyfileurl = [NSURL URLWithString:keyFile];
        if([keyfileurl isFileURL]) {
            keyFilePath = [[keyfileurl.absoluteString
                     stringByRemovingPercentEncoding] substringFromIndex:7];
        } else {
            NSString *documentsDirectory = [KeePassTouchAppDelegate documentsDirectory];
            keyFilePath = [documentsDirectory stringByAppendingPathComponent:keyFile];
        }
    }
    
    // Load the database
    [self performSelectorOnMainThread:@selector(startSpinner) withObject:nil waitUntilDone:YES];
    @try {
        // Open the database
        DatabaseDocument *dd = [[DatabaseDocument alloc] initWithFilename:path password:password keyFile:keyFilePath];
        
        // Store the password in the keychain
        if ([[AppSettings sharedInstance] rememberPasswordsEnabled] || [[AppSettings sharedInstance] isTouchIDEnabled]) {
            [KeychainUtils setString:password forKey:self.selectedFilename
                      andServiceName:@"com.kptouch.passwords"];
            [KeychainUtils setString:keyFile forKey:self.selectedFilename
                      andServiceName:@"com.kptouch.keyfiles"];
        }
        

        // Dismiss the view controller, and after animation set the database document
        [passwordViewController dismissViewControllerAnimated:YES completion:^{
            // Set the database document in the application delegate
            KeePassTouchAppDelegate *appDelegate = [KeePassTouchAppDelegate appDelegate];
            appDelegate.databaseDocument = dd;
        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
        [passwordViewController showErrorMessage:exception.reason];
        [self.spinnerView removeFromSuperview];
        
    }
}

- (void)startSpinner {
    
    [self.spinnerView startAnimating];
}

@end
