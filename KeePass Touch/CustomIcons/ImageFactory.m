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

#import "ImageFactory.h"
#import "KDB4CustomIcon.h"
#import "Kdb4Node.h"
#import "Base64.h"

@interface ImageFactory ()
@property (nonatomic, strong) NSMutableArray *standardImages;
@property (nonatomic, strong) NSDictionary *customImages;
@end

@implementation ImageFactory

- (id)init {
    self = [super init];
    if (self) {
        self.standardImages = [[NSMutableArray alloc] initWithCapacity:NUM_IMAGES];
        for (NSUInteger i = 0; i < NUM_IMAGES; i++) {
            [self.standardImages addObject:[NSNull null]];
            self.customImages = [NSDictionary dictionary];
        }
    }
    return self;
}

+ (ImageFactory *)sharedInstance {
    static ImageFactory *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ImageFactory alloc] init];
    });
    return sharedInstance;
}

- (NSArray *)images {
    // Make sure all the standard images are loaded
    for (NSUInteger i = 0; i < NUM_IMAGES; i++) {
        [self imageForIndex:i];
    }
    return self.standardImages;
}

- (void)clear
{
    self.customImages = nil;
}

- (NSArray *)customs
{
    NSArray *customStrings = [self.customImages allValues];
    NSArray *customIcons = [NSArray array];
    for (NSString *base64String in customStrings) {
        NSData* data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
        customIcons = [customIcons arrayByAddingObject:[ImageFactory imageWithImage:[UIImage imageWithData:data] scaledToSize:CGSizeMake(24, 24)]];
    }
    return customIcons;
}

- (NSArray *)customsKeys
{
    return [self.customImages allKeys];
}

- (NSUInteger)indexForKey:(NSString *)key
{
    NSArray *keys = self.customsKeys;
    NSUInteger i = 0;
    for (i = 0; i < keys.count; i++)
    {
        if ([key compare:[keys objectAtIndex:i]] == NSOrderedSame)
        {
            return i;
        }
    }
    return NSUIntegerMax;
}

- (UIImage *)imageForKey:(NSString *)key
{
    NSString *base64String = (NSString *)[self.customImages valueForKey:key];
    NSData* data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    UIImage *image = [ImageFactory imageWithImage:[UIImage imageWithData:data] scaledToSize:CGSizeMake(20, 20)];
    return image;
}

- (UIImage *)imageForGroup:(KdbGroup *)group {
    
    UIImage *image = nil;
    if([group isKindOfClass:[Kdb4Group class]])
    {
        Kdb4Group *customGroup = (Kdb4Group *)group;
        if(customGroup.customIconUuid != nil)
        {
            NSString *searchKey = [[NSString alloc] initWithData:customGroup.customIconUuid.getData encoding:NSASCIIStringEncoding];
            NSString *base64String = nil;
            if([searchKey hasPrefix:@"@"] == NO) {
                base64String = (NSString *)[self.customImages valueForKey:searchKey];
            }
            if(base64String != nil) {
                NSData* data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
                image = [ImageFactory imageWithImage:[UIImage imageWithData:data] scaledToSize:CGSizeMake(20, 20)];
            }
            else
                [self imageForIndex:group.image];
        }
        else
            image = [self imageForIndex:group.image];
    }
    else
        image = [self imageForIndex:group.image];
    return image;
    
    
    
    
    return [self imageForIndex:group.image];
}

- (UIImage *)imageForEntry:(KdbEntry *)entry {
    UIImage *image = nil;
    if([entry isKindOfClass:[Kdb4Entry class]])
    {
        Kdb4Entry *customEntry = (Kdb4Entry *)entry;
        if(customEntry.customIconUuid != nil)
        {
            NSString *searchKey = [[NSString alloc] initWithData:customEntry.customIconUuid.getData encoding:NSASCIIStringEncoding];
            NSString *base64String = nil;
            if([searchKey hasPrefix:@"@"] == NO) {
                base64String = (NSString *)[self.customImages valueForKey:searchKey];
            }
            if(base64String != nil) {
                NSData* data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
                image = [ImageFactory imageWithImage:[UIImage imageWithData:data] scaledToSize:CGSizeMake(20, 20)];
            }
            else
                image = [self imageForIndex:entry.image];
            
        }
        else
            image = [self imageForIndex:entry.image];
    }
    else
        image = [self imageForIndex:entry.image];
    return image;
}

- (UIImage *)imageForIndex:(NSInteger)index {
    if (index >= NUM_IMAGES) {
        return nil;
    }

    id image = [self.standardImages objectAtIndex:index];
    if (image == [NSNull null]) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"%ld", (long)index]];
        [self.standardImages replaceObjectAtIndex:index withObject:image];
    }

    return image;
}

- (void)initializeWithCustomIcons:(NSArray *)iconsData
{
    NSMutableDictionary *icons = [[NSMutableDictionary alloc] init];
    for (KDB4CustomIcon *ico in iconsData) {
        [icons setValue:ico.data forKey:[[NSString alloc] initWithData:ico.uuid.getData encoding:NSASCIIStringEncoding]];
    }
    self.customImages = icons;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    CGSize sizeWithBorder = CGSizeMake(newSize.width+4.0f, newSize.height+4.0f);
    UIGraphicsBeginImageContextWithOptions(sizeWithBorder, NO, 0.0);
    [image drawInRect:CGRectMake(2, 2, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}



@end
