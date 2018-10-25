/*
 * Copyright 2011-2013 Jason Rush and John Flanagan. All rights reserved.
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
#import "Kdb.h"

@interface ImageFactory : NSObject

#define NUM_IMAGES 69

+ (ImageFactory *)sharedInstance;

- (NSArray *)images;
- (NSArray *)customs;
- (NSArray *)customsKeys;
- (void)initializeWithCustomIcons:(NSArray *)iconsData;
- (void)clear;
- (NSUInteger)indexForKey:(NSString *)key;
- (UIImage *)imageForKey:(NSString *)key;
- (UIImage *)imageForGroup:(KdbGroup *)group;
- (UIImage *)imageForEntry:(KdbEntry *)entry;
- (UIImage *)imageForIndex:(NSInteger)index;

@end
