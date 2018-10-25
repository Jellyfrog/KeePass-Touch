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

#import <UIKit/UIKit.h>
#import "FilesViewController.h"
#import "DatabaseDocument.h"
@import GoogleMobileAds;



@interface KeePassTouchAppDelegate : NSObject <UIApplicationDelegate,GADBannerViewDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) DatabaseDocument *databaseDocument;
@property (nonatomic, assign) BOOL locked;

@property (nonatomic, assign) BOOL bannerIsVisible;
@property (nonatomic, strong) GADBannerView *bannerView;
@property (nonatomic, strong) UIView *currentAd;


@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) FilesViewController *filesViewController;

+ (KeePassTouchAppDelegate *)appDelegate;
+ (NSString *)documentsDirectory;

- (void)closeDatabase;
- (void)deleteKeychainData;
- (void)deleteAllData;

- (void)showSettingsView;
- (void)dismissSettingsView;
- (UINavigationController *)currentNavigationController;

- (void)clearAds;

@end
