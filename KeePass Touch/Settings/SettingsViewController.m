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
#import <LocalAuthentication/LocalAuthentication.h>
#import "KeePassTouchAppDelegate.h"
#import "SettingsViewController.h"
#import "SelectionListViewController.h"
#import "KeychainUtils.h"
#import "AppSettings.h"
#import "MBProgressHUD.h"
#import <MessageUI/MessageUI.h>
#import <Crashlytics/Crashlytics.h>

#define kRemoveAdsProductIdentifier @"KeePassTouch.RemoveAds"


enum {
    SECTION_TOUCHID,
    SECTION_PIN,
    SECTION_DELETE_ON_FAILURE,
    SECTION_CLOSE,
    SECTION_REMEMBER_PASSWORDS,
    SECTION_HIDE_PASSWORDS,
    SECTION_SORTING,
    SECTION_PASSWORD_ENCODING,
    SECTION_CLEAR_CLIPBOARD,
    SECTION_WEB_BROWSER,
    SECTION_FTP,
    SECTION_PURCHASE,
    SECTION_NUMBER
};

enum {
    ROW_PIN_ENABLED,
    ROW_PIN_LOCK_TIMEOUT,
    ROW_PIN_NUMBER
};

enum {
    ROW_DELETE_ON_FAILURE_ENABLED,
    ROW_DELETE_ON_FAILURE_ATTEMPTS,
    ROW_DELETE_ON_FAILURE_NUMBER
};

enum {
    ROW_CLOSE_ENABLED,
    ROW_CLOSE_TIMEOUT,
    ROW_CLOSE_NUMBER
};

enum {
    ROW_REMEMBER_PASSWORDS_ENABLED,
    ROW_REMEMBER_PASSWORDS_NUMBER
};

enum {
    ROW_HIDE_PASSWORDS_ENABLED,
    ROW_HIDE_PASSWORDS_NUMBER
};

enum {
    ROW_SORTING_ENABLED,
    ROW_SORTING_NUMBER
};

enum {
    ROW_PASSWORD_ENCODING_VALUE,
    ROW_PASSWORD_ENCODING_NUMBER
};

enum {
    ROW_CLEAR_CLIPBOARD_ENABLED,
    ROW_CLEAR_CLIPBOARD_TIMEOUT,
    ROW_CLEAR_CLIPBOARD_NUMBER
};

enum {
    ROW_WEB_BROWSER_INTEGRATED,
    ROW_WEB_BROWSER_NUMBER
};

enum {
    ROW_FTP_RESET,
    ROW_FTP_DROPBOX,
    ROW_FTP_DROPBOX_AUTO_SYNC,
    ROW_FTP_NUMBER
};

enum {
    ROW_PURCHASE_BUY,
    ROW_PURCHASE_RESTORE,
    ROW_PURCHASE_NUMBER
};
enum {
    ROW_TOUCHID_DEFAULT,
    ROW_TOUCHID_TOUCHID,
    ROW_TOUCHID_NUMBER
};

@interface SettingsViewController () <MFMailComposeViewControllerDelegate> {
    AppSettings *appSettings;
}
@end

@implementation SettingsViewController

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    appSettings = [AppSettings sharedInstance];

    self.title = NSLocalizedString(@"Settings", nil);
    
    
    pinEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"PIN Enabled", nil)];
    [pinEnabledCell.switchControl addTarget:self
                                     action:@selector(togglePinEnabled:)
                           forControlEvents:UIControlEventValueChanged];
    
    biometryEnabledCell = nil;
    if ([NSClassFromString(@"LAContext") class])
    {
        LAContext *context = [[LAContext alloc] init];
        
        NSError *error = nil;
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
            biometryEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"TouchID Enabled", nil)];
            [biometryEnabledCell.switchControl addTarget:self
                                                 action:@selector(toggleTouchID:)
                                       forControlEvents:UIControlEventValueChanged];
        }
    }
    
    
    KeePassTouchAppDelegate *appDelegate = [KeePassTouchAppDelegate appDelegate];
    NSArray *databaseEntryList = [NSArray arrayWithObject:@"None"];
    databaseEntryList = [databaseEntryList arrayByAddingObjectsFromArray:appDelegate.filesViewController.databaseFiles];
    defaultDatabaseCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Default Database", nil)
                                                    choices:databaseEntryList
                                              selectedIndex:0];
    
    pinLockTimeoutCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Lock Timeout", nil)
                                                   choices:@[NSLocalizedString(@"Immediately", nil),
                                                             NSLocalizedString(@"30 Seconds", nil),
                                                             NSLocalizedString(@"1 Minute", nil),
                                                             NSLocalizedString(@"2 Minutes", nil),
                                                             NSLocalizedString(@"5 Minutes", nil)]
                                             selectedIndex:0];
    
    
    
    deleteOnFailureEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [deleteOnFailureEnabledCell.switchControl addTarget:self
                                                 action:@selector(toggleDeleteOnFailureEnabled:)
                                       forControlEvents:UIControlEventValueChanged];
    
    deleteOnFailureAttemptsCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Attempts", nil)
                                                            choices:@[@"3",
                                                                      @"5",
                                                                      @"10",
                                                                      @"15"]
                                                      selectedIndex:0];
    
    closeEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Close Enabled", nil)];
    [closeEnabledCell.switchControl addTarget:self
                                       action:@selector(toggleCloseEnabled:)
                             forControlEvents:UIControlEventValueChanged];
    
    closeTimeoutCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Close Timeout", nil)
                                                 choices:@[NSLocalizedString(@"Immediately", nil),
                                                           NSLocalizedString(@"30 Seconds", nil),
                                                           NSLocalizedString(@"1 Minute", nil),
                                                           NSLocalizedString(@"2 Minutes", nil),
                                                           NSLocalizedString(@"5 Minutes", nil)]
                                           selectedIndex:0];
    
    rememberPasswordsEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [rememberPasswordsEnabledCell.switchControl addTarget:self
                                                   action:@selector(toggleRememberPasswords:)
                                         forControlEvents:UIControlEventValueChanged];
    
    hidePasswordsCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Hide Passwords", nil)];
    [hidePasswordsCell.switchControl addTarget:self
                                        action:@selector(toggleHidePasswords:)
                              forControlEvents:UIControlEventValueChanged];
    
    sortingEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [sortingEnabledCell.switchControl addTarget:self
                                         action:@selector(toggleSortingEnabled:)
                               forControlEvents:UIControlEventValueChanged];

    passwordEncodingCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Encoding", nil)
                                                     choices:@[NSLocalizedString(@"UTF-8", nil),
                                                               NSLocalizedString(@"UTF-16 Big Endian", nil),
                                                               NSLocalizedString(@"UTF-16 Little Endian", nil),
                                                               NSLocalizedString(@"Latin 1 (ISO/IEC 8859-1)", nil),
                                                               NSLocalizedString(@"Latin 2 (ISO/IEC 8859-2)", nil),
                                                               NSLocalizedString(@"7-Bit ASCII", nil),
                                                               NSLocalizedString(@"Japanese EUC", nil),
                                                               NSLocalizedString(@"ISO-2022-JP", nil)]
                                               selectedIndex:0];

    clearClipboardEnabledCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Enabled", nil)];
    [clearClipboardEnabledCell.switchControl addTarget:self
                                                action:@selector(toggleClearClipboardEnabled:)
                                      forControlEvents:UIControlEventValueChanged];
    
    clearClipboardTimeoutCell = [[ChoiceCell alloc] initWithLabel:NSLocalizedString(@"Clear Timeout", nil)
                                                          choices:@[NSLocalizedString(@"30 Seconds", nil),
                                                                    NSLocalizedString(@"1 Minute", nil),
                                                                    NSLocalizedString(@"2 Minutes", nil),
                                                                    NSLocalizedString(@"3 Minutes", nil)]
                                                    selectedIndex:0];

    webBrowserIntegratedCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Integrated", nil)];
    [webBrowserIntegratedCell.switchControl addTarget:self
                                           action:@selector(toggleWebBrowserIntegrated:)
                                 forControlEvents:UIControlEventValueChanged];

    // Add version number to table view footer
    CGFloat viewWidth = CGRectGetWidth(self.tableView.frame);
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 40)];
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    
    NSString *text = [NSString stringWithFormat:NSLocalizedString(@"KeePass Touch version %@", nil), appVersion];
    UIFont *font = [UIFont boldSystemFontOfSize:17];
    
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 30)];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.backgroundColor = [UIColor clearColor];
    versionLabel.font = font;
    versionLabel.textColor = [UIColor colorWithRed:0.298039 green:0.337255 blue:0.423529 alpha:1.0];
    versionLabel.text = text;
    versionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    versionLabel.shadowColor = [UIColor whiteColor];
    versionLabel.shadowOffset = CGSizeMake(0.0, 1.0);

    [tableFooterView addSubview:versionLabel];
    
    self.tableView.tableFooterView = tableFooterView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Delete the temp pin
    tempPin = nil;
    
    // Initialize all the controls with their settings
    pinEnabledCell.switchControl.on = [appSettings pinEnabled];
    [pinLockTimeoutCell setSelectedIndex:[appSettings pinLockTimeoutIndex]];
    
    deleteOnFailureEnabledCell.switchControl.on = [appSettings deleteOnFailureEnabled];
    [deleteOnFailureAttemptsCell setSelectedIndex:[appSettings deleteOnFailureAttemptsIndex]];
    
    closeEnabledCell.switchControl.on = [appSettings closeEnabled];
    [closeTimeoutCell setSelectedIndex:[appSettings closeTimeoutIndex]];
    
    rememberPasswordsEnabledCell.switchControl.on = [appSettings rememberPasswordsEnabled];
    
    hidePasswordsCell.switchControl.on = [appSettings hidePasswords];
    
    sortingEnabledCell.switchControl.on = [appSettings sortAlphabetically];
    
    [passwordEncodingCell setSelectedIndex:[appSettings passwordEncodingIndex]];
    
    clearClipboardEnabledCell.switchControl.on = [appSettings clearClipboardEnabled];
    [clearClipboardTimeoutCell setSelectedIndex:[appSettings clearClipboardTimeoutIndex]];

    webBrowserIntegratedCell.switchControl.on = [appSettings webBrowserIntegrated];
    
    NSInteger toBeSelected = 0;
    NSInteger defaultdb = [appSettings defaultDatabase];
    KeePassTouchAppDelegate *appDelegate = [KeePassTouchAppDelegate appDelegate];
    if(defaultdb <= (appDelegate.filesViewController.databaseFiles.count))
    {
        toBeSelected = defaultdb;
    }
    else
    {
        toBeSelected = 0;
        [appSettings setDefaultDatabase:0];
    }
    [defaultDatabaseCell setSelectedIndex:toBeSelected];

    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)updateEnabledControls {
    BOOL pinEnabled = [appSettings pinEnabled];
    BOOL deleteOnFailureEnabled = [appSettings deleteOnFailureEnabled];
    BOOL closeEnabled = [appSettings closeEnabled];
    BOOL clearClipboardEnabled = [appSettings clearClipboardEnabled];
    BOOL touchIDEnabled = [appSettings isTouchIDEnabled];
    // Enable/disable the components dependant on settings
    [pinLockTimeoutCell setEnabled:pinEnabled];
    [biometryEnabledCell.switchControl setOn:touchIDEnabled];
    [deleteOnFailureEnabledCell setEnabled:pinEnabled];
    [deleteOnFailureAttemptsCell setEnabled:pinEnabled && deleteOnFailureEnabled];
    [closeTimeoutCell setEnabled:closeEnabled];
    [clearClipboardTimeoutCell setEnabled:clearClipboardEnabled];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_NUMBER;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SECTION_TOUCHID:
            if(biometryEnabledCell != nil)
                return ROW_TOUCHID_NUMBER;
            return ROW_TOUCHID_NUMBER - 1;
        case SECTION_PIN:
            return ROW_PIN_NUMBER;
            
        case SECTION_DELETE_ON_FAILURE:
            return ROW_DELETE_ON_FAILURE_NUMBER;
            
        case SECTION_CLOSE:
            return ROW_CLOSE_NUMBER;
            
        case SECTION_REMEMBER_PASSWORDS:
            return ROW_REMEMBER_PASSWORDS_NUMBER;
            
        case SECTION_HIDE_PASSWORDS:
            return ROW_HIDE_PASSWORDS_NUMBER;
            
        case SECTION_SORTING:
            return ROW_SORTING_NUMBER;
            
        case SECTION_PASSWORD_ENCODING:
            return ROW_PASSWORD_ENCODING_NUMBER;

        case SECTION_CLEAR_CLIPBOARD:
            return ROW_CLEAR_CLIPBOARD_NUMBER;
        case SECTION_WEB_BROWSER:
            return ROW_WEB_BROWSER_NUMBER;
        case SECTION_FTP:
            return ROW_FTP_NUMBER;
        case SECTION_PURCHASE:
            return ROW_PURCHASE_NUMBER;
    }
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_PIN:
            return NSLocalizedString(@"PIN Protection", nil);
            
        case SECTION_DELETE_ON_FAILURE:
            return NSLocalizedString(@"Delete All Data on PIN Failure", nil);
            
        case SECTION_CLOSE:
            return NSLocalizedString(@"Close Database on Timeout", nil);
            
        case SECTION_REMEMBER_PASSWORDS:
            return NSLocalizedString(@"Remember Database Passwords", nil);
            
        case SECTION_HIDE_PASSWORDS:
            return NSLocalizedString(@"Hide Passwords", nil);
            
        case SECTION_SORTING:
            return NSLocalizedString(@"Sorting", nil);
            
        case SECTION_PASSWORD_ENCODING:
            return NSLocalizedString(@"Password Encoding", nil);

        case SECTION_CLEAR_CLIPBOARD:
            return NSLocalizedString(@"Clear Clipboard on Timeout", nil);

        case SECTION_WEB_BROWSER:
            return NSLocalizedString(@"Web Browser", nil);
        case SECTION_FTP:
            return @"FTP & Dropbox";
        case SECTION_TOUCHID:
            return biometryEnabledCell != nil ? [@"Touch ID & " stringByAppendingString:NSLocalizedString(@"Default Database", nil)] : NSLocalizedString(@"Default Database", nil);
        case SECTION_PURCHASE:
            return NSLocalizedString(@"In-App-Purchase", nil);;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case SECTION_PIN:
            return NSLocalizedString(@"Prevent unauthorized access to KeePass Touch with a PIN.", nil);
        case SECTION_TOUCHID:
        {
            NSString *fullDescription = [NSString string];
            if(biometryEnabledCell != nil)
                fullDescription = [NSString stringWithFormat:@"%@ & ",NSLocalizedString(@"Unlock your database quickly with TouchID", nil)];
            fullDescription = [fullDescription stringByAppendingString:NSLocalizedString(@"Choose to open a default database on launch.", nil)];
            return fullDescription;
        }
        case SECTION_DELETE_ON_FAILURE:
            return NSLocalizedString(@"Delete all files and passwords after too many failed attempts.", nil);
            
        case SECTION_CLOSE:
            return NSLocalizedString(@"Automatically close an open database after the selected timeout.", nil);
            
        case SECTION_REMEMBER_PASSWORDS:
            return NSLocalizedString(@"Stores remembered database passwords in the devices's secure keychain.", nil);
            
        case SECTION_HIDE_PASSWORDS:
            return NSLocalizedString(@"Hides passwords when viewing a password entry.", nil);
            
        case SECTION_SORTING:
            return NSLocalizedString(@"Sort Groups and Entries Alphabetically", nil);
            
        case SECTION_PASSWORD_ENCODING:
            return NSLocalizedString(@"The string encoding used for passwords when converting them to database keys.", nil);
            
        case SECTION_CLEAR_CLIPBOARD:
            return NSLocalizedString(@"Clear the contents of the clipboard after a given timeout upon performing a copy.", nil);
            
        case SECTION_WEB_BROWSER:
            return NSLocalizedString(@"Switch between an integrated web browser and Safari.", nil);
            
        case SECTION_PURCHASE:
            return NSLocalizedString(@"Restore or buy the removal of ads. \n That way you will support our cause to bring more features to KeePass Touch", nil);
        
    }
    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"indexPath is %@", [indexPath description]);
    switch (indexPath.section) {
        case SECTION_PIN:
            switch (indexPath.row) {
                case ROW_PIN_ENABLED:
                    return pinEnabledCell;
                case ROW_PIN_LOCK_TIMEOUT:
                    return pinLockTimeoutCell;
            }
            break;
            
        case SECTION_DELETE_ON_FAILURE:
            switch (indexPath.row) {
                case ROW_DELETE_ON_FAILURE_ENABLED:
                    return deleteOnFailureEnabledCell;
                case ROW_DELETE_ON_FAILURE_ATTEMPTS:
                    return deleteOnFailureAttemptsCell;
            }
            break;
            
        case SECTION_CLOSE:
            switch (indexPath.row) {
                case ROW_CLOSE_ENABLED:
                    return closeEnabledCell;
                case ROW_CLOSE_TIMEOUT:
                    return closeTimeoutCell;
            }
            break;
            
        case SECTION_REMEMBER_PASSWORDS:
            switch (indexPath.row) {
                case ROW_REMEMBER_PASSWORDS_ENABLED:
                    return rememberPasswordsEnabledCell;
            }
            break;
            
        case SECTION_HIDE_PASSWORDS:
            switch (indexPath.row) {
                case ROW_HIDE_PASSWORDS_ENABLED:
                    return hidePasswordsCell;
            }
            break;
            
        case SECTION_SORTING:
            switch (indexPath.row) {
                case ROW_SORTING_ENABLED:
                    return sortingEnabledCell;
            }
            break;
            
        case SECTION_PASSWORD_ENCODING:
            switch (indexPath.row) {
                case ROW_PASSWORD_ENCODING_VALUE:
                    return passwordEncodingCell;
            }
            break;
            
            
        case SECTION_CLEAR_CLIPBOARD:
            switch (indexPath.row) {
                case ROW_CLEAR_CLIPBOARD_ENABLED:
                    return clearClipboardEnabledCell;
                case ROW_CLEAR_CLIPBOARD_TIMEOUT:
                    return clearClipboardTimeoutCell;
            }
            break;
        case SECTION_WEB_BROWSER:
            switch (indexPath.row) {
                case ROW_WEB_BROWSER_INTEGRATED:
                    return webBrowserIntegratedCell;
            }
            break;
        case SECTION_FTP:
        {
            if(indexPath.row == ROW_FTP_DROPBOX)
            {
                UITableViewCell *dbCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                dbCell.textLabel.text = NSLocalizedString(@"Reset Dropbox Settings", nil);
                return dbCell;
            }
            else if(indexPath.row == ROW_FTP_DROPBOX_AUTO_SYNC) {
                SwitchCell *dbAutoSyncSwitchCell = [[SwitchCell alloc] initWithLabel:NSLocalizedString(@"Auto Sync", nil)];
                dbAutoSyncSwitchCell.switchControl.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"DBAutoSync"];
                [dbAutoSyncSwitchCell.switchControl addTarget:self action:@selector(toggleAutoSync:) forControlEvents:UIControlEventValueChanged];
                return dbAutoSyncSwitchCell;
            }
            UITableViewCell *ftpCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            ftpCell.textLabel.text = NSLocalizedString(@"Reset FTP data", nil);
            return ftpCell;
        }
            break;
        case SECTION_TOUCHID:
        {
            switch (indexPath.row) {
                case ROW_TOUCHID_DEFAULT:
                    return defaultDatabaseCell;
                    break;
                case ROW_TOUCHID_TOUCHID:
                {
                    if(biometryEnabledCell != nil)
                        return biometryEnabledCell;
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case SECTION_PURCHASE:
        {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = indexPath.row == ROW_PURCHASE_BUY ? NSLocalizedString(@"Remove Ads", nil) : NSLocalizedString(@"Restore Purchase", nil);
            return cell;
        }
            break;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_TOUCHID && indexPath.row == ROW_TOUCHID_DEFAULT)
    {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Default Database", nil);
        selectionListViewController.items = defaultDatabaseCell.choices;
        selectionListViewController.selectedIndex = [appSettings defaultDatabase];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    }
    else if (indexPath.section == SECTION_PIN && indexPath.row == ROW_PIN_LOCK_TIMEOUT && pinEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Lock Timeout", nil);
        selectionListViewController.items = pinLockTimeoutCell.choices;
        selectionListViewController.selectedIndex = [appSettings pinLockTimeoutIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_DELETE_ON_FAILURE && indexPath.row == ROW_DELETE_ON_FAILURE_ATTEMPTS && deleteOnFailureEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Attempts", nil);
        selectionListViewController.items = deleteOnFailureAttemptsCell.choices;
        selectionListViewController.selectedIndex = [appSettings deleteOnFailureAttemptsIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_CLOSE && indexPath.row == ROW_CLOSE_TIMEOUT && closeEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Close Timeout", nil);
        selectionListViewController.items = closeTimeoutCell.choices;
        selectionListViewController.selectedIndex = [appSettings closeTimeoutIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_PASSWORD_ENCODING && indexPath.row == ROW_PASSWORD_ENCODING_VALUE) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Password Encoding", nil);
        selectionListViewController.items = passwordEncodingCell.choices;
        selectionListViewController.selectedIndex = [appSettings passwordEncodingIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    } else if (indexPath.section == SECTION_CLEAR_CLIPBOARD && indexPath.row == ROW_CLEAR_CLIPBOARD_TIMEOUT && clearClipboardEnabledCell.switchControl.on) {
        SelectionListViewController *selectionListViewController = [[SelectionListViewController alloc] initWithStyle:UITableViewStyleGrouped];
        selectionListViewController.title = NSLocalizedString(@"Clear Clipboard Timeout", nil);
        selectionListViewController.items = clearClipboardTimeoutCell.choices;
        selectionListViewController.selectedIndex = [appSettings clearClipboardTimeoutIndex];
        selectionListViewController.delegate = self;
        selectionListViewController.reference = indexPath;
        [self.navigationController pushViewController:selectionListViewController animated:YES];
    }
    else if(indexPath.section == SECTION_FTP) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if(indexPath.row == ROW_FTP_DROPBOX) {
            [DBClientsManager unlinkAndResetClients];
            [defaults removeObjectForKey:@"DBAutoSync"];
            [defaults removeObjectForKey:@"DropboxPath"];
        }
        else if(indexPath.row == ROW_FTP_DROPBOX_AUTO_SYNC)
        {
            // nothing to do here, as the switch handles it
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
        else
        {
            [KeychainUtils deleteStringForKey:@"kptftpserver" andServiceName:@"com.kptouch.ftpaccess"];
            [KeychainUtils deleteStringForKey:@"kptftpport" andServiceName:@"com.kptouch.ftpaccess"];
            [KeychainUtils deleteStringForKey:@"kptftpusername" andServiceName:@"com.kptouch.ftpaccess"];
            [KeychainUtils deleteStringForKey:@"kptftppassword" andServiceName:@"com.kptouch.ftpaccess"];
        }
        
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.detailsLabel.text = NSLocalizedString(@"Reset complete", nil);
        hud.detailsLabel.font = [UIFont fontWithName:@"Andale Mono" size:22];
        hud.margin = 10.f;
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:YES afterDelay:1.5f];
        
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if(indexPath.section == SECTION_PURCHASE) {
        switch (indexPath.row) {
            case ROW_PURCHASE_BUY:
            {
                [Answers logCustomEventWithName:@"Purchase - Buy"
                               customAttributes:@{}];
                
                if([SKPaymentQueue canMakePayments]){
                    NSLog(@"User can make payments");
                    
                    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kRemoveAdsProductIdentifier]];
                    productsRequest.delegate = self;
                    [productsRequest start];
                    
                }
                else{
                    NSLog(@"User cannot make payments due to parental controls");
                    //this is called the user cannot make payments, most likely due to parental controls
                }
            }
                break;
            case ROW_PURCHASE_RESTORE:
            {
                [Answers logCustomEventWithName:@"Purchase - Restore"
                               customAttributes:@{}];
                [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
                [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
            }
                break;
            default:
                break;
        }
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)selectionListViewController:(SelectionListViewController *)controller selectedIndex:(NSInteger)selectedIndex withReference:(id<NSObject>)reference {
    NSIndexPath *indexPath = (NSIndexPath*)reference;
    if (indexPath.section == SECTION_TOUCHID && indexPath.row == ROW_TOUCHID_DEFAULT) {
        [appSettings setDefaultDatabase:selectedIndex];
    }
    else if (indexPath.section == SECTION_PIN && indexPath.row == ROW_PIN_LOCK_TIMEOUT) {
        // Save the user setting
        [appSettings setPinLockTimeoutIndex:selectedIndex];
        
        // Update the cell text
        [pinLockTimeoutCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_DELETE_ON_FAILURE && indexPath.row == ROW_DELETE_ON_FAILURE_ATTEMPTS) {
        // Save the user setting
        [appSettings setDeleteOnFailureAttemptsIndex:selectedIndex];
        
        // Update the cell text
        [deleteOnFailureAttemptsCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_CLOSE && indexPath.row == ROW_CLOSE_TIMEOUT) {
        // Save the user setting
        [appSettings setCloseTimeoutIndex:selectedIndex];
        
        // Update the cell text
        [pinLockTimeoutCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_PASSWORD_ENCODING && indexPath.row == ROW_PASSWORD_ENCODING_VALUE) {
        // Save the user setting
        [appSettings setPasswordEncodingIndex:selectedIndex];
        
        // Update the cell text
        [passwordEncodingCell setSelectedIndex:selectedIndex];
    } else if (indexPath.section == SECTION_CLEAR_CLIPBOARD && indexPath.row == ROW_CLEAR_CLIPBOARD_TIMEOUT) {
        // Save the user setting
        [appSettings setClearClipboardTimeoutIndex:selectedIndex];
        
        // Update the cell text
        [clearClipboardTimeoutCell setSelectedIndex:selectedIndex];
    }
}

- (void)togglePinEnabled:(id)sender {
    if (pinEnabledCell.switchControl.on) {
        PinViewController *pinViewController = [[PinViewController alloc] init];
        pinViewController.textLabel.text = NSLocalizedString(@"Set PIN", nil);
        pinViewController.delegate = self;
        
        [self presentViewController:pinViewController animated:YES completion:nil];
    } else {
        // Delete the PIN and disable the PIN enabled setting
        [KeychainUtils deleteStringForKey:@"PIN" andServiceName:@"com.kptouch.pin"];
        [appSettings setPinEnabled:NO];
        
        // Update which controls are enabled
        [self updateEnabledControls];
    }
}

- (void)toggleTouchID:(id)sender {
    [appSettings setTouchIDEnabled:biometryEnabledCell.switchControl.on];
    // Update which controls are enabled
    [KeychainUtils deleteAllForServiceName:@"com.kptouch.passwords"];
    [KeychainUtils deleteAllForServiceName:@"com.kptouch.keyfiles"];
    [self updateEnabledControls];
}

- (void)toggleAutoSync:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"DBAutoSync"];
    NSLog(@"toggle Auto Sync is now %@", [[NSUserDefaults standardUserDefaults] boolForKey:@"DBAutoSync"] ? @"YES" : @"NO");
}

- (void)toggleDeleteOnFailureEnabled:(id)sender {
    // Update the setting
    [appSettings setDeleteOnFailureEnabled:deleteOnFailureEnabledCell.switchControl.on];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)toggleCloseEnabled:(id)sender {
    // Update the setting
    [appSettings setCloseEnabled:closeEnabledCell.switchControl.on];
    
    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)toggleRememberPasswords:(id)sender {
    // Update the setting
    [appSettings setRememberPasswordsEnabled:rememberPasswordsEnabledCell.switchControl.on];
    
    // Delete all database passwords from the keychain
    [KeychainUtils deleteAllForServiceName:@"com.kptouch.passwords"];
    [KeychainUtils deleteAllForServiceName:@"com.kptouch.keyfiles"];
}

- (void)toggleHidePasswords:(id)sender {
    // Update the setting
    [appSettings setHidePasswords:hidePasswordsCell.switchControl.on];
}

- (void)toggleSortingEnabled:(id)sender {
    // Update the setting
    [appSettings setSortAlphabetically:sortingEnabledCell.switchControl.on];
}

- (void)toggleClearClipboardEnabled:(id)sender {
    // Update the setting
    [appSettings setClearClipboardEnabled:clearClipboardEnabledCell.switchControl.on];

    // Update which controls are enabled
    [self updateEnabledControls];
}

- (void)toggleWebBrowserIntegrated:(id)sender {
    // Update the setting
    [appSettings setWebBrowserIntegrated:webBrowserIntegratedCell.switchControl.on];
}

- (void)pinViewController:(PinViewController *)controller pinEntered:(NSString *)pin {        
    if (tempPin == nil) {
        tempPin = [pin copy];
        
        controller.textLabel.text = NSLocalizedString(@"Confirm PIN", nil);
        
        // Clear the PIN entry for confirmation
        [controller clearEntry];
    } else if ([tempPin isEqualToString:pin]) {
        tempPin = nil;
        
        // Set the PIN and enable the PIN enabled setting
        [KeychainUtils setString:pin forKey:@"PIN" andServiceName:@"com.kptouch.pin"];
        [appSettings setPinEnabled:pinEnabledCell.switchControl.on];
        
        // Update which controls are enabled
        [self updateEnabledControls];
        
        // Remove the PIN view
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        tempPin = nil;
        
        // Notify the user the PINs they entered did not match
        controller.textLabel.text = NSLocalizedString(@"PINs did not match. Try again", nil);
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        // Clear the PIN entry to let them try again
        [controller clearEntry];
    }
}

- (NSString *)wifiAddress {    
    NSString *a = @"Not connected or error occured";
    struct ifaddrs *en = NULL;
    struct ifaddrs *temp = NULL;
    int ret = 0;
    ret = getifaddrs(&en);
    if (ret == 0) {
        temp = en;
        while(temp != NULL) {
            if(temp->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp->ifa_name] isEqualToString:@"en0"])
                    a = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp->ifa_addr)->sin_addr)];
            }
            temp = temp->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(en);
    return a;
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    SKProduct *validProduct = nil;
    unsigned long count = response.products.count;
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        NSLog(@"Products Available!");
        if(validProduct)
            [self purchase:validProduct];
    }
    else if(!validProduct){
        NSLog(@"No products available");
        //this is called if your product id is not valid, this shouldn't be called unless that happens.
    }
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    NSLog(@"received restored transactions: %lu", (unsigned long)queue.transactions.count);
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
        if(transaction.transactionState == SKPaymentTransactionStateRestored){
            NSLog(@"Transaction state -> Restored");
            //called when the user successfully restores a purchase
            [self removeAds];
            [[KeePassTouchAppDelegate appDelegate] clearAds];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
        else if(transaction.transactionState == SKPaymentTransactionStatePurchased) {
            NSLog(@"Transaction state -> Purchased");
            //called when the user successfully purchased
            [self removeAds];
            [[KeePassTouchAppDelegate appDelegate] clearAds];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
        
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        switch (transaction.transactionState){
            case SKPaymentTransactionStatePurchasing:
                    NSLog(@"Transaction state -> Purchasing");
                //called when the user is in the process of purchasing, do not add any of your own code here.
                break;
            case SKPaymentTransactionStatePurchased:
                //this is called when the user has successfully purchased the package (Cha-Ching!)
                [self removeAds];
                NSLog(@"Transaction state -> Purchased");
                [[KeePassTouchAppDelegate appDelegate] clearAds];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state -> Restored");
                [self removeAds];
                [[KeePassTouchAppDelegate appDelegate] clearAds];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finnish
                if(transaction.error.code != SKErrorPaymentCancelled){
                    [Answers logCustomEventWithName:@"Purchase - Error"
                                   customAttributes:@{@"error" : transaction.error.description ? transaction.error.description : @"emptyError"}];
                    NSLog(@"Transaction state -> Cancelled");
                    //the user cancelled the payment ;(
                    if(transaction.error) {
                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                        hud.mode = MBProgressHUDModeCustomView;
                        hud.removeFromSuperViewOnHide = YES;
                        hud.detailsLabel.text = [transaction.error localizedDescription];
                        hud.label.text = NSLocalizedString(@"Error", nil);
                        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_red"]];
                        [hud hideAnimated:YES afterDelay:2.5];
                    }
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred: {
                NSLog(@"Transaction state -> deferred");
            }
        }
    }
}

// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    if(error)
    {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        hud.mode = MBProgressHUDModeCustomView;
        hud.removeFromSuperViewOnHide = YES;
        hud.detailsLabel.text = [error localizedDescription];
        hud.label.text = NSLocalizedString(@"Error", nil);
        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_red"]];
        [hud hideAnimated:YES afterDelay:2.5];
    }
    
}

#pragma mark - Purchase / Restore Methods

- (void)purchase:(SKProduct *)product {
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)removeAds {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"adsRemoved"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - MFMailComposeViewControllerDelegate
-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end
