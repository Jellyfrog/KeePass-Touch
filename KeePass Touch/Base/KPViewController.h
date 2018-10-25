//
//  KPViewController.h
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 20.12.17.
//  Copyright © 2017 Self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SizeDesign.h"
#import "UIView+Layout.h"

@interface KPViewController : UIViewController


#pragma mark - Loading

/**
 *Shows a HUD without a title.
 */
-(void)showLoadingAnimation;

/**
 *Shows a HUD with a title.
 *@param title  The HUD will show this title.
 */
-(void)showLoadingAnimation:(NSString *)title;

/**
 *Shows a HUD with a title and a subtitle.
 *@param title The HUD will show this title.
 *@param subtitle The HUD will show this subtitle.
 */
-(void)showLoadingAnimation:(NSString *)title subtitle:(NSString *)subtitle;

/**
 *Shows a HUD for a maximum period of time
 *@param seconds The maximum period
 */
- (void)showLoadingAnimationForMaximumDuration:(NSTimeInterval)seconds;

/**
 *Removes the HUD from the screen.
 */
-(void)removeLoadingAnimation;

#pragma mark - MessageBar

/**
 *Shows a message that shows an error. This error information contains a title and a description.
 *@param title The message will contain this title.
 *@param description The message will contain this description.
 */
-(void)showErrorMessage:(NSString *)title description:(NSString *)description;

/**
 *Shows a message that shows an error. This error information contains a title and a description.
 *@param title The message will contain this title.
 *@param description The message will contain this description.
 *@param duration The duration the ErrorMessage will be shown
 */
-(void)showErrorMessage:(NSString *)title description:(NSString *)description duration:(double)duration;

/**
 *Shows a message with a success information containing a title and a description.
 *@param title The message will contain this title.
 *@param description The message will contain this description.
 */
-(void)showSuccessMessage:(NSString *)title description:(NSString *)description;

/**
 *Shows a message with a success information containing a title and a description.
 *@param title The message will contain this title.
 *@param description The message will contain this description.
 *@param duration The duration the message will be shown
 */
-(void)showSuccessMessage:(NSString *)title description:(NSString *)description duration:(double)duration;

/**
 *Shows a message containing a title and a description.
 *@param title The message will contain this title.
 *@param description The message will contain this description.
 */
-(void)showInfoMessage:(NSString *)title description:(NSString *)description;

/**
 *Shows a message containing a title and a description.
 *@param title The message will contain this title.
 *@param description The message will contain this description.
 *@param duration The duration the InfoMessage will be shown
 */
-(void)showInfoMessage:(NSString *)title description:(NSString *)description duration:(double)duration;

@end
